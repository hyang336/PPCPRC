import argparse

import globus_sdk
from globus_sdk.scopes import TransferScopes

# parser = argparse.ArgumentParser()
# parser.add_argument("SRC")
# parser.add_argument("DST")
# args = parser.parse_args()

# directory
DST="/C/Users/haozi/OneDrive/Desktop/PhD/fMRI_PrC-PPC_data/ASHS_raw2/"
SRC="/scratch/hyang336/working_dir/PPC_MD/"

# Graham data node Endpoint 
source_endpoint_id = "07baf15f-d7fd-4b6a-bf8a-5b5ef2e229d3"
# Local laptop Endpoint
dest_endpoint_id = "92c7a72e-bdf5-11ed-8cec-f9fa098153fc"

CLIENT_ID = "c94ceeb9-8584-4789-a2f5-f880c580732e"
auth_client = globus_sdk.NativeAppAuthClient(CLIENT_ID)


# we will need to do the login flow potentially twice, so define it as a
# function
#
# we default to using the Transfer "all" scope, but it is settable here
# look at the ConsentRequired handler below for how this is used
def login_and_get_transfer_client(*, scopes=TransferScopes.all):
    # note that 'requested_scopes' can be a single scope or a list
    # this did not matter in previous examples but will be leveraged in
    # this one
    auth_client.oauth2_start_flow(requested_scopes=scopes)
    authorize_url = auth_client.oauth2_get_authorize_url()
    print(f"Please go to this URL and login:\n\n{authorize_url}\n")

    auth_code = input("Please enter the code here: ").strip()
    tokens = auth_client.oauth2_exchange_code_for_tokens(auth_code)
    transfer_tokens = tokens.by_resource_server["transfer.api.globus.org"]

    # return the TransferClient object, as the result of doing a login
    return globus_sdk.TransferClient(
        authorizer=globus_sdk.AccessTokenAuthorizer(transfer_tokens["access_token"])
    )


# get an initial client to try with, which requires a login flow
transfer_client = login_and_get_transfer_client()

# now, try an ls on the source and destination to see if ConsentRequired
# errors are raised
consent_required_scopes = []


def check_for_consent_required(target):
    try:
        transfer_client.operation_ls(target, path="/")
    # catch all errors and discard those other than ConsentRequired
    # e.g. ignore PermissionDenied errors as not relevant
    except globus_sdk.TransferAPIError as err:
        if err.info.consent_required:
            consent_required_scopes.extend(err.info.consent_required.required_scopes)


check_for_consent_required(source_endpoint_id)
check_for_consent_required(dest_endpoint_id)

# the block above may or may not populate this list
# but if it does, handle ConsentRequired with a new login
if consent_required_scopes:
    print(
        "One of your endpoints requires consent in order to be used.\n"
        "You must login a second time to grant consents.\n\n"
    )
    transfer_client = login_and_get_transfer_client(scopes=consent_required_scopes)

# from this point onwards, the example is exactly the same as the reactive
# case, including the behavior to retry on ConsentRequiredErrors. This is
# not obvious, but there are cases in which it is necessary -- for example,
# if a user consents at the start, but the process of building task_data is
# slow, they could revoke their consent before the submission step
#
# in the common case, a single submission with no retry would suffice

task_data = globus_sdk.TransferData(
    source_endpoint=source_endpoint_id, destination_endpoint=dest_endpoint_id
)
ss_list = '.\sub_list_libmotion.txt'
with open(ss_list) as f:
    ss = [line.rstrip() for line in f]

# For-loop to add all items
for i in ss:
    prc_mask = SRC + 'ASHS_raw2/sub-' + i + '/final/sub-' + i + '_PRC_MNINLin6_resampled.nii'
    des_file = DST + 'sub-' + i + '/final/sub-' + i + '_PRC_MNINLin6_resampled.nii'
    task_data.add_item(prc_mask,des_file)


def do_submit(client):
    task_doc = client.submit_transfer(task_data)
    task_id = task_doc["task_id"]
    print(f"submitted transfer, task_id={task_id}")


try:
    do_submit(transfer_client)
except globus_sdk.TransferAPIError as err:
    if not err.info.consent_required:
        raise
    print(
        "Encountered a ConsentRequired error.\n"
        "You must login a second time to grant consents.\n\n"
    )
    transfer_client = login_and_get_transfer_client(
        scopes=err.info.consent_required.required_scopes
    )
    do_submit(transfer_client)