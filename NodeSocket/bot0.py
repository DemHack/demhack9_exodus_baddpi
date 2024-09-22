# NodeSocket.py

from flask import Flask, request, jsonify
from threading import Thread
import subprocess
import docker
import json 

app = Flask(__name__)

def getId(data, extids):
    ids = dict()
    for key, item in enumerate(data):
        if item['name'].startswith('cred'):
            #print(item['name'])
            nameisp = item['name'].split(' ')[0][4:] #splited and cutted outl base item name
            try:
                chunk = int(nameisp.split('_')[0])
                nameisp = int(nameisp.split('_')[1])
            except (IndexError, ValueError): #Index for first chunk, Value for empty 'cred'
                chunk = 0
            try:
                index = extids.index(int(nameisp) + 2**7 * chunk) #index in base
                extchunk = int(extids[index] / 2**7)  #for example, but there is crypto chunks
                if extchunk == chunk:
                    print(nameisp, 'yoy', extchunk, chunk)
                    ids[nameisp] = dict()
                    ids[nameisp]['pos'] = key
                    ids[nameisp]['extpos'] = index
                    if item.get('dataLimit'):
                        ids[nameisp]['old'] = int( item['dataLimit']['bytes'] / 10**6 )
                    else:
                        ids[nameisp]['old'] = None
            except ValueError:
                pass
    return ids
    

@app.route('/webhook/creds', methods=['POST'])
def webhook_cred():
    if request.method == 'POST':
        data = request.json
        resp = parseStream(data)
        resp = list()
        credentials = data['data']['creds']
        with open('/opt/outline/persisted-state/shadowbox_config.json', 'r+') as f:
            base = json.load(f)
            ids = getId(base['accessKeys'], [ cred['id'] for cred in credentials ] )
            #print(ids)
            for key, item in ids.items():
                resp.append({ 'id': key, 'old': item['old'], 'new': credentials[item['extpos']]['mbytes'] })
                base['accessKeys'][item['pos']]['dataLimit'] = dict()
                base['accessKeys'][item['pos']]['dataLimit']['bytes'] = credentials[item['extpos']]['mbytes'] * 10**6
            #print(base)
            #print(resp)
            f.seek(0)        # <--- should reset file position to the beginning.
            json.dump(base, f)
            f.truncate()     # remove remaining part
            #try:
            #    subprocess.check_call(['systemctl', 'restart', 'docker'])
            #    print(f'Restart docker service.')
            #except subprocess.CalledProcessError as e:
            #    print(f'Failed to start docker service: {e}')
            try:
                client = docker.from_env()
                container = client.containers.get('shadowbox')
                container.restart()
                print( f"Successfully restarted shadowbox service. Status:\n", container.status )
            except Exception as e:
                print(f"Failed to start shadowbox service: {e}")
            data['data']['creds'] = resp 
        print("Calculated data: ", data)
        return jsonify(data)

def parseStream(json):
    credentials = json['data']['creds']
    mess = "Credentials executor\n"
    for cred in credentials:
        mess += f"{cred['id']} is here\n"
    return mess

@app.route('/webhook/reload', methods=['POST'])
def webhook_rel():
    def do_after():
        from time import sleep
        sleep(15)
        try:
            print(f'Restart...')
            subprocess.run(["/usr/sbin/shutdown", "-r", "now"])
        except Exception as e:
            print(f'Failed to restart: {e}')
    if request.method == 'POST':
        data = request.json
        if data['data']['doit'] == True:
            print("try to start", data)
            thread = Thread(target=do_after, kwargs={})
            thread.start() 
            return jsonify( {"43.87.104.83": "reload..." } )
        else:
            return "not started"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=12003, ssl_context=('cert.pem', 'key.pem'))
