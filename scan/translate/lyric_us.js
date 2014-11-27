app.factory("lyric", function() {
	return {
		constant: {
			header_login: "Login",
			button_login: "Log in",
			placeholder_username: "username",
			placeholder_password: "password",
			placeholder_search: "search",
			header_profile: "Profile",
			field_firstname: "first name",
			field_lastname: "last name",
			field_companyname: "company name",
			field_registered: "registered",
			field_checkedin: "checkedin",
			header_print: "Print",
			button_close_list: "close list",
			button_add_field: "add field",
			message_1: "Select participant for loading profile",
			message_2: "Loading participant list",
			message_3: "Participant list updated",
			message_4: "No printer installed",
			message_5: "No printer found",
			message_6: "Please input you authorization data",
			message_7: "Authorization data checkin on the server",
			message_8: "Checked-in participant"
		},
		dynamic: new Polyglot({
			phrases: {
				message_1: "Loading participant %{var1} %{var2} profile",
				message_2: "Profile participant %{var1} %{var2} is ready to print",
				message_3: "Status code %{var1}: %{var2}",
				message_4: "Settings %{var1}",
				message_5: "Profile participant %{var1} %{var2} is ready to print",
				message_6: "Print participant %{var1} %{var2} sticker",
				message_7: "Profile participant %{var1} %{var2} is ready to print",
				message_8: "%{var1} user is logged on. Get data about event list",
				message_9: "Data about event %{var1} loaded. Loading participant list",
				message_10: "Participant list for event %{var1} loaded",
				message_11: "Some error at the print: %{var1}"
			}
		})
	};
});