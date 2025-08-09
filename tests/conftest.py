import pytest
from src import SubscriptionConsumer


@pytest.fixture
def subscription_consumer():
    vrf_coordinator = "0xd5D517aBE5cF79B7e95eC98dB0f0277788aFF634"
    key_hash = bytes.fromhex(
        "dc2f87677b01473c763cb0aee938ed3341512f6057324a584e5944e786144d70"
    )
    callback_gas_limit = 1000000
    request_confirmations = 1
    num_words = 1
    subscription_id = 1
    return SubscriptionConsumer.deploy(
        vrf_coordinator,
        key_hash,
        callback_gas_limit,
        request_confirmations,
        num_words,
        subscription_id,
    )
