def test_random_number_from_contract(subscription_consumer):
    """Test that gets a random number using the SubscriptionConsumer smart contract"""
    # Request random words from the VRF coordinator
    request_id = subscription_consumer.requestRandomWords()
    print(f"Random words requested with ID: {request_id}")

    # Get the request status
    fulfilled, random_words = subscription_consumer.getRequestStatus(request_id)
    print(f"Request fulfilled: {fulfilled}")
    print(f"Random words: {random_words}")

    # Basic assertions
    assert request_id > 0
    assert not fulfilled  # Initially not fulfilled until VRF callback
