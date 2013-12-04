# Open-ended listener.
class PeerWeb.Listener
  # @param [PeerWeb.Config] config PeerWeb configuration data
  # @param [PeerWeb.Rtc] rtc WebRTC abstraction layer
  constructor: (config, rtc) ->
    @config = config
    @rtc = rtc
    @createListener()

  createListener: ->
    connection = @rtc.rtcPeerConnection()
    channel = connection.createDataChannel @config.seedChannelLabel,
        id: @config.seedChannelId, reliable: false, negotiated: false,
        ordered: false
    @connection = connection
    @channel = channel

    connection.ondatachannel = (event) =>
      @_onDataChannel connection, event
    connection.onicecandidate = (event) =>
      @_onIceCandidate connection, event
    connection.oniceconnectionstatechange = (event) =>
      @_onIceConnectionStateChange connection, event
    connection.onnegotiationneeded = (event) =>
      @_onNegotiationNeeded connection, event
    connection.onsignalingstatechange = (event) =>
      @_onSignalingStateChange connection, event
    channel.onopen = (event) =>
      @_onDataOpen channel, event
    channel.onerror = (event) =>
      @_onDataError channel, event
    channel.onclose = (event) =>
      @_onDataClose channel, event
    channel.onmessage = (event) =>
      @_onDataMessage channel, event

    connection.createOffer (event) =>
      @_onSdpOffer connection, event

  _onDataChannel: (connection, event) ->
    console.log ['datachannel', event]

  _onIceCandidate: (connection, event) ->
    #console.log ['icecandidate', event]
    if event.candidate is null
      # Done enumerating ICE candidates.
      console.log ['icecandidatedone']
    else
      iceSdp = new PeerWeb.IceSdp event.candidate.candidate
      console.log ['icecandidate', iceSdp]

  _onIceConnectionStateChange: (connection, event) ->
    console.log ['iceconnectionstate', event]

  _onNegotiationNeeded: (connection, event) ->
    console.log ['negotiationneeded', event]

  _onSignalingStateChange: (connection, event) ->
    console.log ['signalingstatechange', event]

  _onSdpOffer: (connection, offer) ->
    sdp = new PeerWeb.Sdp offer.sdp
    console.log ['sdpoffer', sdp]
    console.log offer.sdp

    sdp.setIceCredentials @config.seedChannelListenIceUser,
                          @config.seedChannelListenIcePassword
    #sdp.replaceMediaTransport 'DTLS/SCTP', 'SDES/SCTP'
    sdp.setCrypto @config.seedChannelCrypto
    sdp.setFingerprint @config.seedChannelListenHash
    sdp.removeMediaStreams()
    console.log sdp.toSdpString()

    localDescription = @rtc.rtcSessionDescription sdp, 'offer'
    connection.setLocalDescription localDescription,
        (=> @_onLocalDescriptionSuccess(connection, sdp)),
        (error) => @_onLocalDescriptionError(connection, error)

  _onLocalDescriptionSuccess: (connection, localSdp) ->
    console.log ['localdescriptionsuccess']

    sdp = new PeerWeb.Sdp localSdp.toSdpString()
    sdp.origin.version += 1
    sdp.setIceCredentials @config.seedChannelPushIceUser,
                          @config.seedChannelPushIcePassword
    sdp.replaceMediaTransport 'DTLS/SCTP', 'SCTP'
    sdp.setCrypto @config.seedChannelCrypto
    #sdp.setFingerprint @config.seedChannelPushHash
    sdp.setFingerprint null
    sdp.removeMediaStreams()
    sdp.setIceSetup 'passive'
    console.log sdp.toSdpString()

    remoteDescription = @rtc.rtcSessionDescription sdp, 'answer'
    connection.setRemoteDescription remoteDescription,
        (=> @_onRemoteDescriptionSuccess(connection)),
        (error) => @_onRemoteDescriptionError(connection, error)

  _onLocalDescriptionError: (connection, error) ->
    console.log ['localdescriptionerror', error]

  _onRemoteDescriptionSuccess: (connection) ->
    console.log ['remotedescriptionsuccess']

  _onRemoteDescriptionError: (connection, error) ->
    console.log ['remotedescriptionerror', error]

  _onDataOpen: (channel, event) ->
    console.log ['dataopen', event]

  _onDataClose: (channel, event) ->
    console.log ['dataclose', event]

  _onDataError: (channel, event) ->
    console.log ['dataerror', event]

  _onDataMessage: (channel, event) ->
    console.log ['datamessage', event]
