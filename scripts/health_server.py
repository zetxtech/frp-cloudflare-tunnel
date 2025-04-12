import http.server
import subprocess

class HealthHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        subprocess.call(['/scripts/health_check.sh'])
        self.send_response(200)
        self.send_header('Content-type', 'text/plain')
        self.end_headers()
        with open('/tmp/health_check_result.txt', 'rb') as f:
            self.wfile.write(f.read())

if __name__ == '__main__':
    server = http.server.HTTPServer(('0.0.0.0', 8889), HealthHandler)
    server.serve_forever()