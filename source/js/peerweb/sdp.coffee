# SDP parser and assembler.
class PeerWeb.Sdp
  constructor: (sdpString) ->
    @parse sdpString

  # Replaces this instance data with data parsed from an SDP string.
  #
  # @param {String} sdpString a string containing an SDP offer or answer
  # @return {PeerWeb.Sdp} this, for easy call chaining
  # @see http://tools.ietf.org/html/rfc2327
  parse: (sdpString) ->
    @version = '0'
    @origin = null
    @subject = '-'
    @time = { start: 0, end: 0 }
    @attributes = {}
    @media = []

    globalBandwidth = {}
    globalConnection = null
    globalKey = null
    media = null

    lines = sdpString.split "\r\n"
    for line in lines
      line = line.trim()
      continue if line.length is 0

      if line.substring(1, 2) isnt '='
        throw new Error("Invalid SDP line: #{line}")
      type = line.substring 0, 1
      value = line.substring 2
      switch type
        when 'v'  # Version. Should be 0.
          @version = value
        when 'o'  # Origin.
          originData = value.split ' '
          unless originData.length is 6
            throw new Error("Invalid SDP origin value: #{value}")
          @origin = {
            username: originData[0]
            session_id: originData[1]
            version: parseFloat(originData[2])
            network_type: originData[3]
            address_type: originData[4]
            address: originData[5]
          }
        when 's'  # Subject.
          @subject = value
        when 't'  # Time
          timeData = value.split ' '
          unless timeData.length is 2
            throw new Error("Invalid SDP time value: #{value}")
          @time = {
            start: timeData[0],
            end: timeData[1]
          }
        when 'c'  # Connection.
          connectionData = value.split ' '
          unless connectionData.length is 3
            throw new Error("Invalud SDP connection value: #{value}")
          connection = {
            network_type: connectionData[0],
            address_type: connectionData[1],
            address: connectionData[2]
          }
          if media is null
            globalConnection = connection
          else
            media.connection = connection
        when 'k'  # Encryption key.
          keyData = value.split ':'
          key = {
            method: keyData[0],
            key: keyData[1] or null
          }
          if media is null
            globalKey = key
          else
            media.key = key
        when 'a'  # Attribute
          attrData = value.split ':'
          attrName = attrData[0]
          if attrData.length is 1
            attrValue = true
          else if attrData.length is 2
            attrValue = attrData[1]
          else  # attrData.length > 2
            attrValue = attrData.splice(1).join(':')

          attributes = if media then media.attributes else @attributes
          if attributes[attrName]
            # Multi-value attribute.
            if typeof attributes[attrName] isnt 'object'
              # This attributed only had one value before. Promote to array.
              attributes[attrName] = [attributes[attrName]]
            attributes[attrName].push attrValue
          else
            attributes[attrName] = attrValue
        when 'b'  # Bandwidth limit.
          bwData = value.split ':'
          unless bwData.length is 2
            throw new Error("Invalid SDP bandwidth value: #{value}")
          bwModifier = bwData[0]
          bwValue = bwData[1]
          if media is null
            globalBandwidth[bwModifier] = bwValue
          else
            media.bandwidth[bwModifier] = bwValue

        when 'm'  # Media stream.
          mediaData = value.split ' '
          if mediaData.length < 4
            throw new Error("Invalid SDP media value: #{value}")
          media = {
            media: mediaData[0],
            port: mediaData[1],
            transport: mediaData[2],
            formats: mediaData.splice(3),
            attributes: {},
            connection: globalConnection,
            key: globalKey,
            bandwidth: JSON.parse(JSON.stringify(globalBandwidth))
          }
          @media.push media
    @

  # Turns the information in this instance into an SDP string.
  #
  # @return {String} the SDP string corresponding to this instance's session
  #   description
  toSdpString: ->
    lines = ["v=#{@version}"]

    originLine = "o=#{@origin.username} #{@origin.session_id} " +
        "#{@origin.version} #{@origin.network_type} #{@origin.address_type} " +
        "#{@origin.address}"
    lines.push originLine

    lines.push "s=#{@subject}"
    lines.push "t=#{@time.start} #{@time.end}"
    for attrName, attrValue of @attributes
      if attrValue is true
        lines.push "a=#{attrName}"
      else if typeof attrValue is 'object'
        for value in attrValue
          lines.push "a=#{attrName}:#{value}"
      else
        lines.push "a=#{attrName}:#{attrValue}"

    for media in @media
      mediaLine = "m=#{media.media} #{media.port} #{media.transport} " +
          media.formats.join(' ')
      lines.push mediaLine
      connection = media.connection
      connectionLine = "c=#{connection.network_type} " +
          "#{connection.address_type} #{connection.address}"
      lines.push connectionLine

      if media.key
        key = media.key
        if key.key
          keyLine = "k=#{key.method}:#{key.key}"
        else
          keyLine = "k=#{key.method}"
        lines.push keyLine

      for bwModifier, bwValue of media.bandwidth
        lines.push "b=#{bwModifier}:#{bwValue}"

      for attrName, attrValue of media.attributes
        if attrValue is true
          lines.push "a=#{attrName}"
        else if typeof attrValue is 'object'
          for value in attrValue
            lines.push "a=#{attrName}:#{value}"
        else
          lines.push "a=#{attrName}:#{attrValue}"
    lines.join("\r\n") + "\r\n"

  # Overwrites the ICE username/password in this description.
  #
  # @param {String} user the new value to be used in the 'ice-ufrag' property
  # @param {String} password the new value to be used in the 'ice-pwd' property
  # @return {PeerWeb.Sdp} this, for easy call chaining
  setIceCredentials: (user, password) ->
    for media in @media
      if media.attributes['ice-ufrag']
        media.attributes['ice-ufrag'] = user
      if media.attributes['ice-pwd']
        media.attributes['ice-pwd'] = password
    @

  # Overwrites the ICE candidate for each stream in this description.
  #
  # @param {PeerWeb.IceSdp} iceSdp information for the new ICE candidate
  # @return {PeerWeb.Sdp} this, for easy call chaining
  setIceCandidate: (iceSdp) ->
    for media in @media
      media.attributes['candidate'] = iceSdp.toAttributeString()
    @

  # Overwrites the ICE setup attribute for each stream in this description.
  #
  # @param {String} iceSetup the new value of the setup attribute
  # @return {PeerWeb.Sdp} this, for easy call chaining
  setIceSetup: (iceSetup) ->
    for media in @media
      media.attributes['setup'] = iceSetup
    @

  # Overrides the crypto attribute for each stream in this description.
  #
  # @param {String} crypto the new value of the crypto attribute; if null, the
  #   crypto attribute is removed from each stream
  # @return {PeerWeb.Sdp} this, for easy call chaining
  setCrypto: (crypto) ->
    for media in @media
      if crypto is null
        delete media.attributes['crypto']
      else
        media.attributes['crypto'] = crypto
    @

  # Overrides the fingerprint attribute for each stream in this description.
  #
  # @param {String} fingerprint the new value of the fingerprint attribute; if
  #   null, the fingerprint attribute is removed from each stream
  # @return {PeerWeb.Sdp} this, for easy call chaining
  setFingerprint: (fingerprint) ->
    for media in @media
      if fingerprint is null
        delete media.attributes['fingerprint']
      else
        media.attributes['fingerprint'] = fingerprint
    @

  # Replaces a media transport for each stream in this description.
  #
  # @param {String} oldTransport streams whose media transport match this value
  #   will have the transport replaced
  # @param {String} newTransport streams whose media transport matches the
  #   replacement criterion will have their transport set to this value
  # @return {PeerWeb.Sdp} this, for easy call chaining
  replaceMediaTransport: (oldTransport, newTransport) ->
    for media in @media
      if media.transport is oldTransport
        media.transport = newTransport
    @

  # Removes the non-data streams in this description.
  #
  # @return {PeerWeb.Sdp} this, for easy call chaining
  removeMediaStreams: ->
    if @attributes['group']
      #@attributes['group'] = 'BUNDLE data'
      delete @attributes['group']
    @media = (media for media in @media when media.media is 'application')
    @

# Parser and assembler for the SDP attribute used by ICE candidates.
class PeerWeb.IceSdp
  # @param {String, Object} candidate an SDP string or JavaScript object
  #   containing ICE candidate attributes
  constructor: (candidate) ->
    if typeof candidate is 'string'
      @parse candidate
    else
      @relayAddress = null
      @relayPort = null
      @attributes = {}
      for own attr, value of candidate
        this[attr] = value

  # Replaces this instance data with data from an ICE candidate string.
  #
  # @param {String} candidateString a full SDP entry or the value of candidate:
  #   attribute
  parse: (candidateString) ->
    candidateString = candidateString.trim()
    if candidateString.substring(0, 12) is "a=candidate:"
      candidateString = candidateString.substring 12
    tokens = candidateString.split ' '

    @foundation = tokens[0]
    @component = parseInt tokens[1]
    @transport = tokens[2]
    @priority = tokens[3]
    @address = tokens[4]
    @port = tokens[5]
    if tokens[6] isnt 'typ'
      throw new Error("Invalid ICE candidate value: #{candidateString}")
    @type = tokens[7]

    offset = 8
    if tokens[offset] is 'raddr'
      @relayAddress = tokens[offset + 1]
      offset += 2
    else
      @relayAddress = null
    if tokens[offset] is 'rport'
      @relayPort = tokens[offset + 1]
      offset += 2
    else
      @relayPort = null

    @attributes = {}
    while offset < tokens.length
      @attributes[tokens[offset]] = tokens[offset + 1]
      offset += 2

    @

  # Turns the candidate information into an SDP attribute value.
  #
  # @return {String} an SDP attribute value that can be assigned to the
  #   "candidate" attribute in a larger SDP
  toAttributeString: ->
    tokens = [@foundation, @component.toString(), @transport, @priority,
        @address, @port, 'typ', @type]
    if @relayAddress
      tokens.push 'raddr'
      tokens.push @relayAddress
    if @relayPort
      tokens.push 'rport'
      tokens.push @relayPort
    for attrName, attrValue of @attributes
      tokens.push attrName
      tokens.push attrValue
    tokens.join ' '

  # Turns the candidate information into an SDP string.
  #
  # @return {String} an SDP string representing this ICE candidate's
  #   information; this can be used in a call to
  #   {RTCPeerConnection.addIceCandidate}
  toSdpString: ->
    "a=candidate:#{@toSdpValue()}\n"
