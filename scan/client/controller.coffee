app.controller "ScanController", ($scope, lyric, $filter, resource, connect, $rootScope, $sce, storage, $timeout, message, freelancer, scroll, loader, events, participants, alertt, print) ->

	$scope.freelancer = freelancer

	$scope.events = events

	$scope.participants = participants

	$scope.message = message

	$scope.scroll = scroll

	$scope.loader = loader

	$scope.alert = alertt

	$scope.print = print

	$scope.lyric = lyric

	$scope.participants.lastParticipantActive = undefined

	$scope.button =
		cheskedinButtonTag: "checkin"
		createButton: "create"

	participantActive = (participant) ->
		message.setNeutral $scope.lyric.dynamic.t "message_1", var1: participant.last_name, var2: participant.first_name
		if participant.status is "checkedin"
			$scope.button.cheskedinButtonTag = "print"
		else
			$scope.button.cheskedinButtonTag = "checkin"
		if $scope.participants.lastParticipantActive and $scope.participants.lastParticipantActive.active
			$scope.participants.lastParticipantActive.active = no
			$scope.participants.lastParticipantActive = null
		participant.active = yes
		if participant isnt $scope.participants.lastParticipantActive
			$scope.participants.lastParticipantActive = participant
			$scope.participants.activeParticipant = null
			$scope.participants.loadProfile participant
				.then (participantProfile) ->
					if $scope.participants.lastParticipantActive and $scope.participants.lastParticipantActive.id is participantProfile.id
						message.setSuccess $scope.lyric.dynamic.t "message_2", var1: participant.last_name, var2: participant.first_name
						participant.options = participantProfile.options
						$scope.participants.activeParticipant = participant
						$scope.print.addComplateProfile participantProfile
					if $scope.alert.active
						if $scope.alert.active is "print"
							$scope.print.printSetting participantProfile
						$timeout ->
							$scope.alert.updatePosition()
				, (profileError) ->
					$scope.print.clear()
					$timeout ->
						$scope.alert.updatePosition()
					message.setError $scope.lyric.dynamic.t "message_3", var1: profileError.status, var2: profileError.statusText

	participantPassive = ->
		message.setNeutral $scope.lyric.constant.message_1
		$scope.participants.activeParticipant = null
		if $scope.participants.lastParticipantActive and $scope.participants.lastParticipantActive.active
			$scope.participants.lastParticipantActive.active = no
			$scope.participants.lastParticipantActive = null
		if $scope.button.cheskedinButtonTag isnt "checkin"
			$scope.button.cheskedinButtonTag = "checkin"

	$scope.$watch "participants.searchString", (searchString) ->
		participantList = $scope.participants.filter searchString
		if participantList and participantList.length is 1
			participantActive participantList[0]
		else if participantList
			participantPassive()

	$scope.participants.selectParticipant = (participant) ->
		if participant isnt $scope.participants.lastParticipantActive
			participantActive participant
		else
			participantPassive()

	$scope.participants.refreshParticipantsList = ->
		if not $scope.participants.refresh
			$scope.participants.refresh = on
			$scope.participants.activeParticipant = null
			message.setNeutral $scope.lyric.constant.message_2
			participants.load().then (participantsList) ->
				if $scope.freelancer.profile
					participants.participantsList = participantsList
					participants.filter()
					participants.updateChecinsCount()
					$timeout ->
						scroll.scrollElement()
					if $scope.participants.lastParticipantActive
						angular.forEach $scope.participants.participantsList, (participant) ->
							if participant.id is $scope.participants.lastParticipantActive.id
								participantActive participant
					message.setSuccess $scope.lyric.constant.message_3
					$scope.participants.refresh = off
			, (participantsError) ->
				message.setError $scope.lyric.dynamic.t "message_3", var1: participantsError.status, var2: participantsError.statusText
				$scope.participants.refresh = off

	iframe = document.querySelector "iframe"

	openRegistration = ->
		iframe.src = $sce.trustAsResourceUrl "http://#{domain}/event/#{$scope.events.activeEvent.event_alias}"
		$scope.button.createButton = "close"

	$scope.alert.wrapToggle = (name) ->
		state = $scope.alert.toggle name
		if state.name
			if $scope.participants.activeParticipant
				message.setNeutral $scope.lyric.dynamic.t "message_4", var1: state.name
				if state.name is "print"
					$scope.print.printSetting $scope.participants.activeParticipant
					$timeout ->
						$scope.alert.updatePosition()
				if state.name is "registration"
					openRegistration()
				if state.name is "profile"
					$timeout ->
						$scope.alert.updatePosition()
			else
				if state.name is "registration"
					openRegistration()
			if state.pre is "registration"
				$scope.participants.refreshParticipantsList()
				$scope.button.createButton = "create"
		else
			if $scope.participants.activeParticipant
				message.setSuccess $scope.lyric.dynamic.t "message_5", var1: $scope.participants.activeParticipant.last_name, var2: $scope.participants.activeParticipant.first_name
			else
				message.setNeutral $scope.lyric.constant.message_1
			if state.pre is "print"
				if $scope.print.cacheFunc
					$scope.print.cacheFunc()
					$scope.print.cacheFunc = null
			if state.pre is "registration"
				$scope.participants.refreshParticipantsList()
				$scope.button.createButton = "create"
		$scope.alert.active = state.name

	$scope.participants.checkedinOrPrint = (participant) ->
		if $scope.print.printSettings[participant.form_id]
			if participant.status is "checkedin"
				message.setNeutral $scope.lyric.dynamic.t "message_6", var1: participant.last_name, var2: participant.first_name
				$scope.print.printеParticipant participant
			else
				$scope.participants.checkin participant
				.then ->
					if $scope.participants.activeParticipant and $scope.participants.activeParticipant.status is "checkedin"
						$scope.button.cheskedinButtonTag = "print"
					else
						$scope.button.cheskedinButtonTag = "checkin"
					$scope.participants.checkedinOrPrint participant
		else
			$scope.alert.wrapToggle "print"
			$scope.print.cacheFunc = ->
				$scope.participants.checkedinOrPrint participant

	searchField = document.querySelector "input[search]"

	$scope.print.printеParticipant = (participant) ->
		searchField.focus()
		searchField.select()
		img = new Image()
		img.crossOrigin = 'anonymous'
		img.onload = ->
			canvas = document.createElement 'canvas'
			canvas.width = img.width
			canvas.height = img.height
			context = canvas.getContext '2d'
			context.drawImage img, 0, 0
			dataUrl = canvas.toDataURL 'image/png'
			pngBase64 = dataUrl.substr ('data:image/png;base64,').length

			labelToPrintTemplateHead = labelToPrintTemplateTextBody = ""
			n = 0
			angular.forEach $scope.print.printSettings[participant.form_id].activeField, (field, i) ->
				value = $scope.print.getField(field, participant).$$unwrapTrustedValue()
				value = if value isnt field.label then value else ""
				if value
					if n is 0
						labelToPrintTemplateHead = '<?xml version="1.0" encoding="utf-8"?>
																					<DieCutLabel Version="8.0" Units="twips">
																						<PaperOrientation>Landscape</PaperOrientation>
																						<Id>Shipping</Id>
																						<PaperName>30323 Shipping</PaperName>
																						<DrawCommands>
																							<RoundRectangle X="0" Y="0" Width="3060" Height="5715" Rx="270" Ry="270"/>
																						</DrawCommands>
																						<ObjectInfo>
																							<TextObject>
																								<Name>TEXT</Name>
																								<ForeColor Alpha="255" Red="0" Green="0" Blue="0"/>
																								<BackColor Alpha="0" Red="255" Green="255" Blue="255"/>
																								<LinkedObjectName></LinkedObjectName>
																								<Rotation>Rotation0</Rotation>
																								<IsMirrored>False</IsMirrored>
																								<IsVariable>False</IsVariable>
																								<HorizontalAlignment>Left</HorizontalAlignment>
																								<VerticalAlignment>Middle</VerticalAlignment>
																								<TextFitMode>AlwaysFit</TextFitMode>
																								<UseFullFontHeight>True</UseFullFontHeight>
																								<Verticalized>False</Verticalized>
																								<StyledText>
																									<Element>
																										<String>' + $scope.print.getField(field, participant) + '</String>
																										<Attributes>
																											<Font Family="Arial" Size="13" Bold="' + field.bold + '" Italic="False" Underline="False" Strikeout="False"/>
																											<ForeColor Alpha="255" Red="0" Green="0" Blue="0"/>
																										</Attributes>
																									</Element>
																								</StyledText>
																							</TextObject>
																							<Bounds X="310" Y="130" Width="5150" Height="630"/>
																						</ObjectInfo>'
					
					else
						labelToPrintTemplateTextBody += '<ObjectInfo>
																							<TextObject>
																								<Name>TEXT_1</Name>
																								<ForeColor Alpha="255" Red="0" Green="0" Blue="0"/>
																								<BackColor Alpha="0" Red="255" Green="255" Blue="255"/>
																								<LinkedObjectName></LinkedObjectName>
																								<Rotation>Rotation0</Rotation>
																								<IsMirrored>False</IsMirrored>
																								<IsVariable>False</IsVariable>
																								<HorizontalAlignment>Left</HorizontalAlignment>
																								<VerticalAlignment>Middle</VerticalAlignment>
																								<TextFitMode>AlwaysFit</TextFitMode>
																								<UseFullFontHeight>True</UseFullFontHeight>
																								<Verticalized>False</Verticalized>
																								<StyledText>
																									<Element>
																										<String>' + $scope.print.getField(field, participant) + '</String>
																										<Attributes>
																											<Font Family="Arial" Size="13" Bold="' + field.bold + '" Italic="False" Underline="False" Strikeout="False"/>
																											<ForeColor Alpha="255" Red="0" Green="0" Blue="0"/>
																										</Attributes>
																									</Element>
																								</StyledText>
																							</TextObject>
																							<Bounds X="310" Y="' + (500 * n + 130) + '" Width="3100" Height="630"/>
																						</ObjectInfo>'
					n++	

			labelToPrintTemplateQrcode = '<ObjectInfo>
																			<ImageObject>
																				<Name>GRAPHIC</Name>
																				<ForeColor Alpha="255" Red="0" Green="0" Blue="0"/>
																				<BackColor Alpha="0" Red="255" Green="255" Blue="255"/>
																				<LinkedObjectName></LinkedObjectName>
																				<Rotation>Rotation0</Rotation>
																				<IsMirrored>False</IsMirrored>
																				<IsVariable>False</IsVariable>
																				<Image>' + pngBase64 + '</Image>
																				<ScaleMode>Uniform</ScaleMode>
																				<BorderWidth>0</BorderWidth>
																				<BorderColor Alpha="255" Red="0" Green="0" Blue="0"/>
																				<HorizontalAlignment>Center</HorizontalAlignment>
																				<VerticalAlignment>Center</VerticalAlignment>
																			</ImageObject>
																			<Bounds X="3555.166" Y="960" Width="2075.234" Height="2011.525"/>
																		</ObjectInfo>'

			labelToPrintTemplateEnd = '</DieCutLabel>'

			labelToPrintTemplate = labelToPrintTemplateHead + labelToPrintTemplateTextBody + labelToPrintTemplateQrcode + labelToPrintTemplateEnd

			printers = dymo.label.framework.getPrinters()

			try
				if printers.length is 0
					message.setError $scope.lyric.constant.message_4
		
				printerName = null
				for printer in printers
					if printer.printerType is "LabelWriterPrinter"
						printerName = printer.name
						break
	
				if printerName is ""
					message.setError $scope.lyric.constant.message_5
		
				label = dymo.label.framework.openLabelXml labelToPrintTemplate
	
				label.print printerName

				if printerName
					message.setSuccess $scope.lyric.dynamic.t "message_7", var1: $scope.participants.activeParticipant.last_name, var2: $scope.participants.activeParticipant.first_name
			catch error
				message.setError $scope.lyric.dynamic.t "message_11", var1: error
		
		img.src = "https://chart.googleapis.com/chart?chs=200x200&cht=qr&chl=#{$scope.participants.activeParticipant.barcode}&choe=UTF-8"