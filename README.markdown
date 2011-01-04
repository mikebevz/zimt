# Under development

Zimt is a pair of utility classes including an objective-c websocket implementation. I'm in the process of wrapping it in a set of tests and testing ZTWebSocket against the [draft-hixie-thewebsocketprotocol-76][1] and [draft-abarth-websocket-handshake-01][2] drafts for the websocket protocol. 

[1]: http://tools.ietf.org/html/draft-hixie-thewebsocketprotocol-76
[2]: http://tools.ietf.org/html/draft-abarth-websocket-handshake-01

# Testing

1. Clone this repository
2. Checkout the Expectacular submodule (from [https://github.com/eahanson/Expectacular][3])

	`git submodule init; git submodule update`
	
3. Run the `Unit Tests` build targets. [GTM][4] unit test output will appear in the build results as part of the build process.

[3]: https://github.com/eahanson/Expectacular
[4]: http://code.google.com/p/google-toolbox-for-mac/wiki/iPhoneUnitTesting