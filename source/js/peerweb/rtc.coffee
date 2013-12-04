# WebRTC utilities.
class PeerWeb.Rtc
  constructor: (config) ->
    @config = config
    @rtcPeerConnectionClass()

  # Creates a RTCPeerConnection.
  #
  # @return {RTCPeerConnection} a new RTCPeerConnection instance, configured
  #   with the appropriate STUN / TURN servers
  rtcPeerConnection: ->
    constructor = @rtcPeerConnectionClass()
    mandatoryConstraints = [
      { RtpDataChannels: true },
      { DtlsSrtpKeyAgreement: false },
      { OfferToReceiveVideo: false },
      { OfferToReceiveAudio: false },
      { RequestIdentity: 'no' },
    ]
    optionalConstraints = [
      { IceRestart: false },
    ]
    new constructor { iceServers: @config.iceServers },
        { mandatory: mandatoryConstraints, optional: optionalConstraints }

  # Creates a RTCSessionDescription.
  #
  # @param {PeerWeb.Sdp} sdp the SDP information to be wrapped in the
  #   RTCSessionDescription
  # @param {String} type 'offer' or 'answer'
  # @return {RTCSessionDescription} a RTCSessionDescription wrapping the given
  #   SDP
  rtcSessionDescription: (sdp, type) ->
    constructor = RTCSessionDescription
    new constructor sdp: sdp.toSdpString(), type: type

  # The (browser-dependent) constructor for the RTCPeerConnection class.
  #
  # @return {function()} the RTCPeerConnection constructor
  rtcPeerConnectionClass: ->
    if @_rtcPeerConnectionClass
      return @_rtcPeerConnectionClass

    if typeof RTCPeerConnection is 'function'
      @_rtcPeerConnectionClass = RTCPeerConnection
    else if typeof webkitRTCPeerConnection is 'function'
      @_rtcPeerConnectionClass = webkitRTCPeerConnection
    else if typeof mozRTCPeerConnection is 'function'
      @_rtcPeerConnectionClass = mozRTCPeerConnection
    else
      throw new Error("Missing WebRTC support!")

    return @_rtcPeerConnectionClass
