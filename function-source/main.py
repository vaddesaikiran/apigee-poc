import functions_framework
import json

@functions_framework.http
def hello_world(request):
    """HTTP Cloud Function that returns a greeting."""
    request_json = request.get_json(silent=True)
    request_args = request.args

    if request_json and 'name' in request_json:
        name = request_json['name']
    elif request_args and 'name' in request_args:
        name = request_args['name']
    else:
        name = 'World'
    
    return json.dumps({
        'message': f'Hello {name}!',
        'status': 'success'
    }), 200, {'Content-Type': 'application/json'}
