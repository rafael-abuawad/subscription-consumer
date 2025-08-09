# pragma version ~=0.4.3
# pragma nonreentrancy off
"""
@title Subscription Consumer
@custom:contract-name SubscriptionConsumer
@license GNU Affero General Public License v3.0 only
@author rabuawad <x.com/rabuawad_>
@notice This is an example contract that uses hardcoded values for clarity.
        This is an example contract that uses un-audited code.
        Do not use this code in production.
"""

# @dev Declare the VRFCoordinatorV2Plus interface
interface IVRFCoordinatorV2Plus:
    def requestRandomWords(req: RandomWordsRequest) -> uint256: nonpayable


# @dev We import and initialise the `ownable` module.
from snekmate.auth import ownable as ow
initializes: ow


event RequestSent:
    requestId: uint256
    numWords: uint32


event RequestFulfilled:
    requestId: uint256
    randomWords: DynArray[uint256, MAX_NUM_WORDS]


event CoordinatorSet:
    coordinator: indexed(address)


struct RequestStatus:
    fulfilled: bool
    exists: bool
    randomWords: DynArray[uint256, MAX_NUM_WORDS]


struct RandomWordsRequest:
    keyHash: bytes32
    subId: uint64
    requestConfirmations: uint16
    callbackGasLimit: uint32
    numWords: uint32
    extraArgs: Bytes[MAX_ARGS_SIZE]


struct ExtraArgsV1:
    nativePayment: bool


MAX_ARGS_SIZE: constant(uint256) = 1_024

MAX_REQUEST_IDS: constant(uint256) = 256

MAX_NUM_WORDS: constant(uint32) = 16

EXTRA_ARGS_V1_TAG: public(constant(bytes4)) = 0x92FD1338  # == `bytes4(keccak256("VRF ExtraArgsV1"))`


# @dev The VRF coordinator address.
vrfCoordinator: public(IVRFCoordinatorV2Plus)


# @dev The key hash of the VRF coordinator.
# The gas lane to use, which specifies the maximum gas price to bump to.
# For a list of available gas lanes on each network,
# see https://docs.chain.link/vrf/v2-5/supported-networks
keyHash: public(
    constant(bytes32)
) = 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae


# @dev The subscription ID of the VRF coordinator.
# Depends on the number of requested values that you want sent to the
# fulfillRandomWords() function. Storing each word costs about 20,000 gas,
# so 100,000 is a safe default for this example contract. Test and adjust
# this limit based on the network that you select, the size of the request,
# and the processing of the callback request in the fulfillRandomWords()
# function.
callbackGasLimit: public(constant(uint32)) = 1000000


# @dev The default is 3, but you can set this higher.
requestConfirmations: public(constant(uint16)) = 3


# @dev For this example, retrieve 2 random values in one request.
# Cannot exceed VRFCoordinatorV2_5.MAX_NUM_WORDS.
numWords: public(constant(uint32)) = 2


# @dev The subscription ID of the VRF coordinator.
subscriptionId: public(uint64)


# @dev A mapping of request IDs to request statuses.
_requests: HashMap[uint256, RequestStatus]


# @dev A mapping of request IDs to request statuses.
_requestIds: DynArray[uint256, MAX_REQUEST_IDS]


# @dev A list of requested random words.
_randomWords: DynArray[uint256, MAX_ARGS_SIZE]


@deploy
def __init__(vrfCoordinator: address):
    assert vrfCoordinator != empty(address)
    self.vrfCoordinator = IVRFCoordinatorV2Plus(vrfCoordinator)
    ow.__init__()


@internal
@view
def _args_to_bytes(extra_args: ExtraArgsV1) -> Bytes[MAX_ARGS_SIZE]:
    return abi_encode(extra_args, method_id=EXTRA_ARGS_V1_TAG)


@internal
def _fulfillRandomWords(
    requestId: uint256, randomWords: DynArray[uint256, MAX_NUM_WORDS]
) -> bool:
    """
    @dev VRFConsumerBaseV2Plus expects its subcontracts to have a method with this
            signature, and will call it once it has verified the proof
            associated with the randomness. (It is triggered via a call to
            rawFulfillRandomness, below.)
    @notice fulfillRandomness handles the VRF response. Your contract must
            implement it. See "SECURITY CONSIDERATIONS" above for important
            principles to keep in mind when implementing your fulfillRandomness
            method.
    @param requestId The Id initially returned by requestRandomness
    @param randomWords the VRF output expanded to the requested number of words
    @return bool - True if the fulfillment is successful
    """
    assert self._requests[requestId].exists  # Request must exist
    self._requests[requestId].fulfilled = True
    self._requests[requestId].randomWords = randomWords
    log RequestFulfilled(requestId=requestId, randomWords=randomWords)
    return False


@external
def requestRandomWords() -> uint256:
    """
    @dev Request random words from the VRF coordinator
    @return requestId The ID of the request
    """
    requestId: uint256 = extcall self.vrfCoordinator.requestRandomWords(
        RandomWordsRequest(
            keyHash=keyHash,
            subId=self.subscriptionId,
            requestConfirmations=requestConfirmations,
            callbackGasLimit=callbackGasLimit,
            numWords=numWords,
            extraArgs=self._args_to_bytes(ExtraArgsV1(nativePayment=False)),
        )
    )
    randomWords: DynArray[uint256, MAX_NUM_WORDS] = []
    self._requests[requestId] = RequestStatus(
        fulfilled=False, exists=True, randomWords=randomWords
    )
    self._requestIds.append(requestId)
    log RequestSent(requestId=requestId, numWords=numWords)
    return requestId


@external
def rawFulfillRandomWords(
    requestId: uint256, randomWords: DynArray[uint256, MAX_NUM_WORDS]
):
    """
    @dev rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
            proof. rawFulfillRandomness then calls fulfillRandomness, after validating
            the origin of the call
    """
    assert msg.sender == self.vrfCoordinator.address  # Only the VRF coordinator can fulfill the request
    self._fulfillRandomWords(requestId, randomWords)


@external
def setCoordinator(vrfCoordinator: address):
    """
    @dev Set the VRF coordinator address
    @param vrfCoordinator The new VRF coordinator address
    """
    ow._check_owner()
    assert vrfCoordinator != empty(address)
    self.vrfCoordinator = IVRFCoordinatorV2Plus(vrfCoordinator)
    log CoordinatorSet(coordinator=vrfCoordinator)


@external
@view
def getRequestStatus(
    requestId: uint256,
) -> (bool, DynArray[uint256, MAX_NUM_WORDS]):
    assert self._requests[requestId].exists  # Request must exist
    request: RequestStatus = self._requests[requestId]
    return (request.fulfilled, request.randomWords)


@external
@view
def lastRequestId() -> uint256:
    return self._requestIds[len(self._requestIds) - 1]
