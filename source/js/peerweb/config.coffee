# Configuration that can be done before PeerWeb is initialized.
class PeerWeb.Config
  # Sets up the default configuration.
  constructor: ->
    @iceServers = ({ url: url } for url in @defaultIceServers())
    @seedChannelLabel = 'peerweb'
    @seedChannelId = 1
    @seedChannelListenIceUser = 'PeerWebICEListenUser'
    @seedChannelListenIcePassword = 'PeerWebICEListenPassword'
    @seedChannelPushIceUser = 'PeerWebICEPushUser'
    @seedChannelPushIcePassword = 'PeerWebICEPushPassword'
    @seedChannelCrypto =
        '0 AES_CM_128_HMAC_SHA1_80 inline:o1WntMPfTDqKE2ppWMzVtmdTRnklFNH4LtCC9Bw0'
    @seedChannelListenHash =
        'sha-256 7E:77:AB:88:F4:DA:54:6F:B0:49:50:72:CE:FC:0F:33:08:D4:9D:AE:AB:FB:17:EB:A0:87:58:B2:87:F0:56:17'
    @seedChannelPushHash =
        'sha-256 DF:42:88:1D:22:EE:C5:D3:EE:BB:D5:93:80:45:1F:9E:F1:9B:89:F4:24:B1:17:EF:92:28:B1:DA:76:22:CE:9C'

  # @property {Array<RTCIceServer>} list of TURN and STUN servers
  iceServers: null

  # @property {String} the label of the data channel used to seed connections
  seedChannelLabel: null

  # @property {Number} the id of the data channel used to seed connections
  seedChannelId: null

  # @property {String} the ice-ufrag used by the seed connection listener
  seedChannelListenIceUser: null

  # @property {String} the ice-password used by the seed connection listener
  seedChannelListenIcePassword: null

  # @property {String} the ice-ufrag used by the seed connection pusher
  seedChannelPushIceUser: null

  # @property {String} the ice-password used by the seed connection pusher
  seedChannelPushIcePassword: null

  # @property {String} the encryption for the channel used to seed connections
  seedChannelCrypto: null

  # @property {String} the fingerprint of the listener in the seed connection
  seedChannelListenHash: null

  # @property {String} the fingerprint of the pusher in the seed connection
  seedChannelPushHash: null

  # @return {Array<String>} URLs for the default TURN and STUN servers
  defaultIceServers: ->
    [
      'stun:stun.l.google.com:19302',
      'stun:stun1.l.google.com:19302',
      'stun:stun2.l.google.com:19302',
      'stun:stun3.l.google.com:19302',
      'stun:stun4.l.google.com:19302',
      'stun:stun01.sipphone.com',
      'stun:stun.ekiga.net',
      'stun:stun.fwdnet.net',
      'stun:stun.ideasip.com',
      'stun:stun.iptel.org',
      'stun:stun.rixtelecom.se',
      'stun:stun.schlund.de',
      'stun:stunserver.org',
      'stun:stun.softjoys.com',
      'stun:stun.voiparound.com',
      'stun:stun.voipbuster.com',
      'stun:stun.voipstunt.com',
      'stun:stun.voxgratia.org',
      'stun:stun.xten.com',
      'stun:numb.viagenie.ca',
      'stun:stun.counterpath.net',
    ]
