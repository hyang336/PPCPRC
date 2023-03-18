# #pull ASHS results to local, preserving directory structure
import globus_sdk
from globus_sdk.scopes import TransferScopes

CLIENT_ID = "c94ceeb9-8584-4789-a2f5-f880c580732e"
auth_client = globus_sdk.NativeAppAuthClient(CLIENT_ID)

# requested_scopes specifies a list of scopes to request
# instead of the defaults, only request access to the Transfer API
auth_client.oauth2_start_flow(requested_scopes=TransferScopes.all)
authorize_url = auth_client.oauth2_get_authorize_url()
print(f"Please go to this URL and login:\n\n{authorize_url}\n")

auth_code = input("Please enter the code here: ").strip()
tokens = auth_client.oauth2_exchange_code_for_tokens(auth_code)
transfer_tokens = tokens.by_resource_server["transfer.api.globus.org"]

# construct an AccessTokenAuthorizer and use it to construct the
# TransferClient
transfer_client = globus_sdk.TransferClient(
    authorizer=globus_sdk.AccessTokenAuthorizer(transfer_tokens["access_token"])
)

# Globus Tutorial Endpoint 1
source_endpoint_id = "07baf15f-d7fd-4b6a-bf8a-5b5ef2e229d3"
# Globus Tutorial Endpoint 2
dest_endpoint_id = "92c7a72e-bdf5-11ed-8cec-f9fa098153fc"

# create a Transfer task consisting of one or more items
task_data = globus_sdk.TransferData(
    source_endpoint=source_endpoint_id, destination_endpoint=dest_endpoint_id
)

# directory
local_des="/C/Users/haozi/OneDrive/Desktop/PhD/fMRI_PrC-PPC_data/ASHS_raw2/"
source_des="/home/hyang336/scratch/working_dir/PPC_MD/ASHS_raw2/"

task_data.add_item(
    "/share/godata/file1.txt",  # source
    "/~/minimal-example-transfer-script-destination.txt",  # dest
)

# submit, getting back the task ID
task_doc = transfer_client.submit_transfer(task_data)
task_id = task_doc["task_id"]
print(f"submitted transfer, task_id={task_id}")

# import globus_sdk

# # client ID
# CLIENT_ID = "c94ceeb9-8584-4789-a2f5-f880c580732e"
# client = globus_sdk.NativeAppAuthClient(CLIENT_ID)

# client.oauth2_start_flow(refresh_tokens=True)
# authorize_url = client.oauth2_get_authorize_url()
# print(f"Please go to this URL and login:\n\n{authorize_url}\n")
# #this token is only good for 10 min
# auth_code = input("Please enter the code here: ").strip()
# token_response = client.oauth2_exchange_code_for_tokens(auth_code)

# globus_auth_data = token_response.by_resource_server["auth.globus.org"]
# globus_transfer_data = token_response.by_resource_server["transfer.api.globus.org"]

# # the refresh token and access token are often abbreviated as RT and AT
# transfer_rt = globus_transfer_data["refresh_token"]
# transfer_at = globus_transfer_data["access_token"]
# expires_at_s = globus_transfer_data["expires_at_seconds"]

# # construct a RefreshTokenAuthorizer
# # note that `client` is passed to it, to allow it to do the refreshes
# authorizer = globus_sdk.RefreshTokenAuthorizer(
#     transfer_rt, client, access_token=transfer_at, expires_at=expires_at_s
# )
# tc = globus_sdk.TransferClient(authorizer=authorizer)

# # high level interface; provides iterators for list responses
# print("My Endpoints:")
for ep in tc.endpoint_search("graham"):
    print("[{}] {}".format(ep["id"], ep["display_name"]))


