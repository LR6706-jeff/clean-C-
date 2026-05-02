import os
import json
import uuid
import base64
import time
import itertools
import threading
import requests
import win32crypt
from flask import Flask, request, Response, jsonify, render_template
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

app = Flask(__name__)

# --- Configuration ---
ACCOUNTS_FILE = "accounts.json"
QCLAW_GATEWAY_URL = "https://na-long.qclaw.qq.com/aizone/v1/chat/completions"
QCLAW_MODEL = "modelroute"

# --- State ---
class AccountPool:
    def __init__(self):
        self.accounts = []
        self.stats = {} # token -> {success: 0, fail: 0, last_used: 0}
        self.lock = threading.Lock()
        self.load()
        self._iterator = itertools.cycle(self.accounts) if self.accounts else None

    def load(self):
        if os.path.exists(ACCOUNTS_FILE):
            try:
                with open(ACCOUNTS_FILE, "r") as f:
                    self.accounts = json.load(f)
            except:
                self.accounts = []
        
        for acc in self.accounts:
            if acc not in self.stats:
                self.stats[acc] = {"success": 0, "fail": 0, "last_used": 0}
        
        if self.accounts:
            self._iterator = itertools.cycle(self.accounts)
        else:
            self._iterator = None

    def save(self):
        with open(ACCOUNTS_FILE, "w") as f:
            json.dump(self.accounts, f, indent=2)

    def add(self, token):
        with self.lock:
            if token not in self.accounts:
                self.accounts.append(token)
                self.stats[token] = {"success": 0, "fail": 0, "last_used": 0}
                self.save()
                self._iterator = itertools.cycle(self.accounts)
                return True
            return False

    def remove(self, token):
        with self.lock:
            if token in self.accounts:
                self.accounts.remove(token)
                self.save()
                self._iterator = itertools.cycle(self.accounts) if self.accounts else None
                return True
            return False

    def get_next(self):
        with self.lock:
            if not self.accounts:
                return None
            token = next(self._iterator)
            self.stats[token]["last_used"] = time.time()
            return token

    def log_result(self, token, success):
        with self.lock:
            if token in self.stats:
                if success:
                    self.stats[token]["success"] += 1
                else:
                    self.stats[token]["fail"] += 1

pool = AccountPool()

# --- QClaw Logic ---
def get_current_qclaw_token():
    try:
        local_state_path = os.path.expanduser(r"~\AppData\Roaming\QClaw\Local State")
        app_store_path = os.path.expanduser(r"~\AppData\Roaming\QClaw\app-store.json")
        with open(local_state_path, "r", encoding="utf-8") as f:
            ls = json.load(f)
        with open(app_store_path, "r", encoding="utf-8") as f:
            as_json = json.load(f)
        ek = base64.b64decode(ls["os_crypt"]["encrypted_key"])[5:]
        dk = win32crypt.CryptUnprotectData(ek, None, None, None, 0)[1]
        ct = as_json["authGateway.providers.qclaw.apiKey"]["cipherText"]
        ed = base64.b64decode(ct)
        aesgcm = AESGCM(dk)
        return aesgcm.decrypt(ed[3:15], ed[15:], None).decode("utf-8")
    except: return None

# --- Admin App ---
admin_app = Flask(__name__)

@admin_app.route("/")
def dashboard():
    return render_template("index.html")

@admin_app.route("/api/accounts")
def list_accounts():
    data = []
    for acc in pool.accounts:
        data.append({
            "id": acc[:15] + "...",
            "token": acc,
            "success": pool.stats[acc]["success"],
            "fail": pool.stats[acc]["fail"],
            "last_used": time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(pool.stats[acc]["last_used"])) if pool.stats[acc]["last_used"] > 0 else "Never"
        })
    return jsonify(data)

@admin_app.route("/api/harvest", methods=["POST"])
def harvest():
    token = get_current_qclaw_token()
    if not token:
        return jsonify({"error": "No QClaw token found. Please login first."}), 400
    added = pool.add(token)
    return jsonify({"success": True, "added": added})

@admin_app.route("/api/accounts", methods=["DELETE"])
def delete_account():
    token = request.args.get("token")
    removed = pool.remove(token)
    return jsonify({"success": removed})

# --- Proxy App ---
proxy_app = Flask(__name__ + "_proxy")

def anthropic_to_openai_messages(anthropic_msgs, system_prompt):
    openai_msgs = []
    if system_prompt:
        openai_msgs.append({"role": "system", "content": system_prompt})
    
    for msg in anthropic_msgs:
        role = msg["role"]
        content = msg["content"]
        
        if isinstance(content, list):
            if any(block.get("type") == "tool_result" for block in content):
                for block in content:
                    if block["type"] == "tool_result":
                        openai_msgs.append({
                            "role": "tool",
                            "tool_call_id": block["tool_use_id"],
                            "content": str(block.get("content", ""))
                        })
            else:
                text_content = ""
                tool_calls = []
                for block in content:
                    if block["type"] == "text":
                        text_content += block["text"]
                    elif block["type"] == "tool_use":
                        tool_calls.append({
                            "id": block["id"],
                            "type": "function",
                            "function": {
                                "name": block["name"],
                                "arguments": json.dumps(block["input"])
                            }
                        })
                
                item = {"role": role, "content": text_content}
                if tool_calls:
                    item["tool_calls"] = tool_calls
                openai_msgs.append(item)
        else:
            openai_msgs.append({"role": role, "content": content})
            
    return openai_msgs

@proxy_app.route("/v1/messages", methods=["POST"])
def proxy_messages():
    data = request.json
    anthropic_msgs = data.get("messages", [])
    system = data.get("system", "")
    stream = data.get("stream", False)
    tools = data.get("tools", [])
    
    openai_msgs = anthropic_to_openai_messages(anthropic_msgs, system)
    openai_req = {
        "model": QCLAW_MODEL,
        "messages": openai_msgs,
        "stream": stream
    }
    
    if tools:
        openai_req["tools"] = []
        for tool in tools:
            openai_req["tools"].append({
                "type": "function",
                "function": {
                    "name": tool["name"],
                    "description": tool.get("description", ""),
                    "parameters": tool["input_schema"]
                }
            })

    def generate(resp_iter, used_token):
        next_index = 0
        has_text_block = False
        active_tool_calls = {}
        text_buffer = ""
        in_think = False
        success = False

        try:
            for line in resp_iter:
                if line:
                    line = line.decode('utf-8')
                    if line.startswith("data: ") and line != "data: [DONE]":
                        success = True
                        chunk = json.loads(line[6:])
                        if not chunk.get("choices"): continue
                        delta = chunk["choices"][0].get("delta", {})
                        
                        if "content" in delta and delta["content"]:
                            if not has_text_block:
                                yield f"event: content_block_start\ndata: {json.dumps({'type': 'content_block_start', 'index': next_index, 'content_block': {'type': 'text', 'text': ''}})}\n\n"
                                has_text_block = True
                                next_index += 1
                            
                            text_idx = next_index - 1
                            text_buffer += delta["content"]
                            while True:
                                if not in_think:
                                    think_start = text_buffer.find("<think>")
                                    if think_start != -1:
                                        if think_start > 0:
                                            yield f"event: content_block_delta\ndata: {json.dumps({'type': 'content_block_delta', 'index': text_idx, 'delta': {'type': 'text_delta', 'text': text_buffer[:think_start]}})}\n\n"
                                        text_buffer = text_buffer[think_start + 7:]
                                        in_think = True
                                    else:
                                        partial_idx = -1
                                        for i in range(1, 7):
                                            if text_buffer.endswith("<think>"[:i]):
                                                partial_idx = len(text_buffer) - i
                                                break
                                        if partial_idx != -1:
                                            if partial_idx > 0:
                                                yield f"event: content_block_delta\ndata: {json.dumps({'type': 'content_block_delta', 'index': text_idx, 'delta': {'type': 'text_delta', 'text': text_buffer[:partial_idx]}})}\n\n"
                                            text_buffer = text_buffer[partial_idx:]
                                        else:
                                            if text_buffer:
                                                yield f"event: content_block_delta\ndata: {json.dumps({'type': 'content_block_delta', 'index': text_idx, 'delta': {'type': 'text_delta', 'text': text_buffer}})}\n\n"
                                            text_buffer = ""
                                        break
                                else:
                                    think_end = text_buffer.find("</think>")
                                    if think_end != -1:
                                        text_buffer = text_buffer[think_end + 8:]
                                        if text_buffer.startswith("\n"): text_buffer = text_buffer[1:]
                                        in_think = False
                                    else:
                                        partial_idx = -1
                                        for i in range(1, 8):
                                            if text_buffer.endswith("</think>"[:i]):
                                                partial_idx = len(text_buffer) - i
                                                break
                                        if partial_idx != -1: text_buffer = text_buffer[partial_idx:]
                                        else: text_buffer = ""
                                        break

                        if "tool_calls" in delta:
                            for tc in delta["tool_calls"]:
                                tc_idx = tc["index"]
                                if tc_idx not in active_tool_calls:
                                    if has_text_block:
                                        if text_buffer and not in_think:
                                            yield f"event: content_block_delta\ndata: {json.dumps({'type': 'content_block_delta', 'index': next_index - 1, 'delta': {'type': 'text_delta', 'text': text_buffer}})}\n\n"
                                            text_buffer = ""
                                        yield f"event: content_block_stop\ndata: {json.dumps({'type': 'content_block_stop', 'index': next_index - 1})}\n\n"
                                        has_text_block = False
                                    
                                    active_tool_calls[tc_idx] = next_index
                                    tc_id = tc['id']
                                    if tc_id.startswith('call_'): tc_id = 'toolu_' + tc_id[5:]
                                    yield f"event: content_block_start\ndata: {json.dumps({'type': 'content_block_start', 'index': next_index, 'content_block': {'type': 'tool_use', 'id': tc_id, 'name': tc['function']['name']}})}\n\n"
                                    next_index += 1
                                
                                g_idx = active_tool_calls[tc_idx]
                                if "function" in tc and "arguments" in tc["function"] and tc["function"]["arguments"]:
                                    yield f"event: content_block_delta\ndata: {json.dumps({'type': 'content_block_delta', 'index': g_idx, 'delta': {'type': 'input_json_delta', 'partial_json': tc['function']['arguments']}})}\n\n"

            pool.log_result(used_token, success)
            if has_text_block:
                if text_buffer and not in_think:
                    yield f"event: content_block_delta\ndata: {json.dumps({'type': 'content_block_delta', 'index': next_index - 1, 'delta': {'type': 'text_delta', 'text': text_buffer}})}\n\n"
                yield f"event: content_block_stop\ndata: {json.dumps({'type': 'content_block_stop', 'index': next_index - 1})}\n\n"
            for g_idx in active_tool_calls.values():
                yield f"event: content_block_stop\ndata: {json.dumps({'type': 'content_block_stop', 'index': g_idx})}\n\n"
            yield f"event: message_delta\ndata: {json.dumps({'type': 'message_delta', 'delta': {'stop_reason': 'end_turn', 'stop_sequence': None}, 'usage': {'output_tokens': 0}})}\n\n"
            yield f"event: message_stop\ndata: {json.dumps({'type': 'message_stop'})}\n\n"
        except Exception as e:
            pool.log_result(used_token, False)
            print(f"Stream error: {e}")

    # Main Request with Rotation
    max_tries = max(1, len(pool.accounts))
    for i in range(max_tries):
        target_token = pool.get_next()
        if not target_token:
            return jsonify({"error": "No accounts available in pool"}), 503
            
        headers = {"Authorization": f"Bearer {target_token}", "Content-Type": "application/json"}
        resp = requests.post(QCLAW_GATEWAY_URL, headers=headers, json=openai_req, stream=stream)
        
        if resp.status_code in [401, 429] and i < max_tries - 1:
            pool.log_result(target_token, False)
            print(f"[!] Token failed ({resp.status_code}), rotating...")
            continue
            
        if stream:
            msg_id = f"msg_{uuid.uuid4().hex}"
            def stream_wrap():
                yield f"event: message_start\ndata: {json.dumps({'type': 'message_start', 'message': {'id': msg_id, 'type': 'message', 'role': 'assistant', 'content': [], 'model': 'claude-3-5-sonnet-20241022', 'stop_reason': None, 'stop_sequence': None, 'usage': {'input_tokens': 0, 'output_tokens': 0}}})}\n\n"
                yield from generate(resp.iter_lines(), target_token)
            return Response(stream_wrap(), content_type="text/event-stream")
        else:
            return jsonify(resp.json())

if __name__ == "__main__":
    from threading import Thread
    
    def run_proxy():
        print(f"[*] API Proxy Server started on http://localhost:18832")
        proxy_app.run(port=18832, debug=False, threaded=True)

    def run_admin():
        print(f"[*] Management Dashboard started on http://localhost:18833")
        admin_app.run(port=18833, debug=False)

    Thread(target=run_proxy).start()
    run_admin()
