# Connects to an open-ended listener.
class PeerWeb.Pusher
  # @param [String] address the IP address to connect to
  # @param [PeerWeb.Config] config PeerWeb configuration data
  # @param [PeerWeb.Rtc] rtc WebRTC abstraction layer
  constructor: (address, config, rtc) ->
    if address.indexOf(':') is -1
      @targetAddress = address
      @targetPort = '0'
    else
      [@targetAddress, @targetPort] = address.split ':'
    @config = config
    @rtc = rtc
    @createPusher()

  createPusher: ->
    connection = @rtc.rtcPeerConnection()
    channel = connection.createDataChannel @config.seedChannelLabel,
        reliable: false, negotiated: false, id: @config.seedChannelId
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

    sdp.setIceCredentials @config.seedChannelListenIceUser,
                          @config.seedChannelListenIcePassword
    sdp.replaceMediaTransport 'DTLS/SCTP', 'SCTP'
    sdp.setCrypto @config.seedChannelCrypto
    sdp.setFingerprint null
    #sdp.setFingerprint @config.seedChannelListenHash
    sdp.removeMediaStreams()

    transport = if @targetPort is '0' then 'tcp' else 'udp'
    iceSdp = new PeerWeb.IceSdp(
        foundation: '1', component: '1', priority: '1', type: 'host',
        address: @targetAddress, port: @targetPort, transport: transport,
        attributes: { generation: '0' })
    sdp.setIceCandidate iceSdp
    console.log sdp.toSdpString()

    remoteDescription = @rtc.rtcSessionDescription sdp, 'offer'
    connection.setRemoteDescription remoteDescription,
        (=> @_onRemoteDescriptionSuccess(connection)),
        (error) => @_onRemoteDescriptionError(connection, error)

  _onSdpAnswer: (connection, answer) ->
    console.log ['sdpanswer', answer]
    sdp = new PeerWeb.Sdp answer.sdp
    sdp.setIceCredentials @config.seedChannelPushIceUser,
                          @config.seedChannelPushIcePassword
    sdp.replaceMediaTransport 'DTLS/SCTP', 'SCTP'
    sdp.setCrypto @config.seedChannelCrypto
    sdp.setFingerprint @config.seedChannelPushHash
    sdp.removeMediaStreams()
    sdp.setIceSetup 'passive'
    console.log sdp.toSdpString()

    localDescription = @rtc.rtcSessionDescription sdp, 'answer'
    connection.setLocalDescription localDescription,
        (=> @_onLocalDescriptionSuccess(connection)),
        (error) => @_onLocalDescriptionError(connection, error)

  _onLocalDescriptionSuccess: (connection) ->
    console.log ['localdescriptionsuccess']
    @channel.send "ohaiiii"

  _onLocalDescriptionError: (connection, error) ->
    console.log ['localdescriptionerror', error]

  _onRemoteDescriptionSuccess: (connection) ->
    console.log ['remotedescriptionsuccess']
    connection.createAnswer (event) =>
      @_onSdpAnswer connection, event

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
