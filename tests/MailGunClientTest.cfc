component output=false {

	function beforeAll() output=false {
		mailGunClient = new cfmailgun.MailGunClient(
			  apiKey        = "ITDOESNOTMATTER_WE_WILL_MOCK_ANY_REAL_CALLS"
			, defaultDomain = "test.domain.com"
		);

		mailGunClient.privateMethodRunner = privateMethodRunner;

		mailGunClient = prepareMock( mailGunClient );
	}

	function run() output=false {

		describe( "API Response processing", function(){

			it( "should return deserialized json from MailGun response", function(){
				var response = { some="simple", object="here" };
				var processed = mailGunClient.privateMethodRunner(
					  method = "_processApiResponse"
					, args   = { status_code = 200, filecontent = SerializeJson( response ) }
				);

				expect( processed ).toBe( response );
			} );

			it( "should throw error when response is not json", function(){
				expect( function(){
					mailGunClient.privateMethodRunner(
						  method = "_processApiResponse"
						, args   = { status_code = 200, filecontent = "some non-json response" }
					);
				} ).toThrow(
					  type  = "cfmailgun.unexpected"
					, regex = "^Unexpected error processing MailGun API response\. MailGun response body: \[some non-json response\]"
				);
			} );

			it( "should throw error when response code is not 200", function(){
				expect( function(){
					mailGunClient.privateMethodRunner(
						  method = "_processApiResponse"
						, args   = { status_code = 3495, filecontent = SerializeJson( { message="hello" } ) }
					);
				} ).toThrow();
			} );

			it( "should show MailGun provided message in thrown errors", function(){
				expect( function(){
					mailGunClient.privateMethodRunner(
						  method = "_processApiResponse"
						, args   = { status_code = 400, filecontent = SerializeJson( { message="something went wrong here" } ) }
					);
				} ).toThrow( regex="something went wrong here" );
			} );

			it( "should show response body itself in thrown errors when response does not contain error message", function(){
				expect( function(){
					mailGunClient.privateMethodRunner(
						  method = "_processApiResponse"
						, args   = { status_code = 401, filecontent = "this is a test" }
					);
				} ).toThrow( regex="this is a test" );
			} );

		} );

		describe( "The SendMessage() method", function(){
			it( "should send a POST request to: /(domain)/messages", function(){
				var callLog = "";

				mailGunClient.$( "_restCall", { message="nice one, ta", id="some id" } );

				mailGunClient.sendMessage(
					  from    = "test from"
					, to      = "test to"
					, subject = "test subject"
					, text    = "test text"
					, html    = "test html"
					, domain  = "some.domain.com"
				);

				callLog = mailGunClient.$callLog();

				expect( callLog._restCall[1].httpMethod ?: "" ).toBe( "POST" );
				expect( callLog._restCall[1].uri        ?: "" ).toBe( "/messages" );
			} );

			it ( "should send all required post vars to MailGun", function(){
				var callLog = "";

				mailGunClient.$( "_restCall", { message="nice one, ta", id="some id" } );

				mailGunClient.sendMessage(
					  from    = "test from"
					, to      = "test to"
					, subject = "test subject"
					, text    = "test text"
					, html    = "test html"
					, domain  = "some.domain.com"
				);

				callLog = mailGunClient.$callLog();

				expect( callLog._restCall[1].postVars ?: {} ).toBe( {
					  from    = "test from"
					, to      = "test to"
					, subject = "test subject"
					, text    = "test text"
					, html    = "test html"
				} );
			} );

			it( "should return newly created message ID from MailGun response", function(){
				mailGunClient.$( "_restCall", { message="nice one, ta", id="a test" } );

				var result = mailGunClient.sendMessage(
					  from    = "test from"
					, to      = "test to"
					, subject = "test subject"
					, text    = "test text"
					, html    = "test html"
					, domain  = "some.domain.com"
				);

				expect( result ).toBe( "a test" );
			} );

			it ( "should throw a suitable error when no ID is returned in the MailGun response", function(){
				mailGunClient.$( "_restCall", { message="nice one, ta - message queued" } );

				expect( function(){
					mailGunClient.sendMessage(
						  from    = "test from"
						, to      = "test to"
						, subject = "test subject"
						, text    = "test text"
						, html    = "test html"
						, domain  = "some.domain.com"
					);
				} ).toThrow(
					  type  = "cfmailgun.unexpected"
					, regex = "Unexpected error processing mail send\. Expected an ID of successfully sent mail but instead received \["
				);
			} );

			it( "should send attachments and inline attachments as files to MailGun", function(){
				var callLog = "";

				mailGunClient.$( "_restCall", { message="nice one, ta", id="some new id" } );

				mailGunClient.sendMessage(
					  from              = "another test from"
					, to                = "another test to"
					, subject           = "another test subject"
					, text              = "another test text"
					, html              = "another test html"
					, domain            = "another.domain.com"
					, attachments       = [ "C:\somefile.txt", "Z:\files\yetanother.zip" ]
					, inlineAttachments = [ "C:\pics\me.jpg", "D:\animated-log.gif", "C:\another.jpg" ]
				);

				callLog = mailGunClient.$callLog();

				expect( callLog._restCall[1].files ?: {} ).toBe( {
					  attachment = [ "C:\somefile.txt", "Z:\files\yetanother.zip" ]
					, inline     = [ "C:\pics\me.jpg", "D:\animated-log.gif", "C:\another.jpg" ]
				} );

			} );

			it( "should send 'o:testing' post var when test mode specified", function(){
				var callLog = "";

				mailGunClient.$( "_restCall", { message="nice one, ta", id="some new id" } );

				mailGunClient.sendMessage(
					  from      = "some test from"
					, to        = "some test to"
					, subject   = "some test subject"
					, text      = "some test text"
					, html      = "some test html"
					, testMode  = true
					, domain    = "some.domain.com"
				);

				callLog = mailGunClient.$callLog();

				expect( callLog._restCall[1].postVars ?: {} ).toBe( {
					  from         = "some test from"
					, to           = "some test to"
					, subject      = "some test subject"
					, text         = "some test text"
					, html         = "some test html"
					, "o:testmode" = "yes"
				} );
			} );

			it( "should send all optional post vars when specified as arguments", function(){
				var callLog = "";

				mailGunClient.$( "_restCall", { message="nice one, ta", id="some new id" } );

				mailGunClient.sendMessage(
					  from            = "some test from"
					, to              = "some test to"
					, cc              = "test cc"
					, bcc             = "test bcc"
					, subject         = "some test subject"
					, text            = "some test text"
					, html            = "some test html"
					, domain          = "some.domain.com"
					, tags            = ["tag1","another tag"]
					, campaign        = "campaign id"
					, dkim            = true
					, deliveryTime    = "2014-01-10 09:00"
					, tracking        = false
					, clickTracking   = "htmlonly"
					, openTracking    = true
					, customHeaders   = { Custom = "testing custom", AnotherCustom = "testing custom again" }
					, customVariables = { someVariable = "a test variable", fubar="test" }
				);

				callLog = mailGunClient.$callLog();

				expect( callLog._restCall[1].postVars ?: {} ).toBe( {
					  from                = "some test from"
					, to                  = "some test to"
					, cc                  = "test cc"
					, bcc                 = "test bcc"
					, subject             = "some test subject"
					, text                = "some test text"
					, html                = "some test html"
					, "o:tag"             = ["tag1","another tag"]
					, "o:campaign"        = "campaign id"
					, "o:dkim"            = "yes"
					, "o:deliverytime"    = httpDateFormat( "2014-01-10 09:00" )
					, "o:tracking"        = "no"
					, "o:tracking-clicks" = "htmlonly"
					, "o:tracking-opens"  = "yes"
					, "h:X-Custom"        = "testing custom"
					, "h:X-AnotherCustom" = "testing custom again"
					, "v:someVariable"    = "a test variable"
					, "v:fubar"           = "test"
				} );
			} );
		} );

		describe( "The listCampaigns() method", function(){

			it( "should send a GET request to: /(domain)/campaigns", function(){
				var callLog = "";

				mailGunClient.$( "_restCall", { total_count=0, items=[] } );

				mailGunClient.listCampaigns( domain = "some.domain.com" );

				callLog = mailGunClient.$callLog();

				expect( callLog._restCall[1].httpMethod ?: "" ).toBe( "GET" );
				expect( callLog._restCall[1].uri        ?: "" ).toBe( "/campaigns" );
				expect( callLog._restCall[1].domain     ?: "" ).toBe( "some.domain.com" );
			} );

			it( "should return total count and array of items from API call", function(){
				var result     = "";
				var mockResult = {
					"total_count": 1,
					"items": [{
						"delivered_count": 924,
						"name": "Sample",
						"created_at": "Wed, 15 Feb 2012 11:31:17 GMT",
						"clicked_count": 135,
						"opened_count": 301,
						"submitted_count": 998,
						"unsubscribed_count": 44,
						"bounced_count": 20,
						"complained_count": 3,
						"id": "1",
						"dropped_count": 13
					}
				]}

				mailGunClient.$( "_restCall", mockResult );

				result = mailGunClient.listCampaigns( domain="some.domain.com" );

				expect( result ).toBe( mockResult );
			} );

			it( "should send optional limit and skip get vars when passed", function(){
				var callLog = "";

				mailGunClient.$( "_restCall", { total_count : 0, items : [] } );

				mailGunClient.listCampaigns( domain = "some.domain.com", limit=50, skip=3 );

				callLog = mailGunClient.$callLog();

				expect( callLog._restCall[1].getVars.limit ?: "" ).toBe( 50 );
				expect( callLog._restCall[1].getVars.skip  ?: "" ).toBe( 3  );
			} );

			it( "should throw suitable error when API return response is not in expected format", function(){
				mailGunClient.$( "_restCall", { total_count : 5 } );

				expect( function(){
					mailGunClient.listCampaigns();
				} ).toThrow(
					  type  = "cfmailgun.unexpected"
					, regex = "Expected response to contain \[total_count\] and \[items\] keys\. Instead, receieved: \["
				);

			} );

		} );
	}


// helper to test private methods
	function privateMethodRunner( method, args ) output=false {
		return this[method]( argumentCollection=args );
	}

	private function httpDateFormat( required date theDate ) output=false {
		var dtGMT = DateAdd( "s", GetTimeZoneInfo().UTCTotalOffset, theDate );

		return DateFormat( dtGMT, "ddd, dd mmm yyyy" ) & " " & TimeFormat( dtGMT, "HH:mm:ss")  & " GMT";
	}

}