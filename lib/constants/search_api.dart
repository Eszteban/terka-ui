const bool useProxy = bool.fromEnvironment('USE_PROXY', defaultValue: true);
const String proxyBaseUrl = String.fromEnvironment('PROXY_URL', defaultValue: 'https://eszteban.hu/api/mav_api_proxy_tester.php');

String get searchApiUrl => useProxy 
    ? '$proxyBaseUrl?endpoint=stations' 
    : 'https://mavplusz.hu/otp2-backend/otp/routers/default/geocode/stations';

String get planApiUrl => useProxy 
    ? '$proxyBaseUrl?endpoint=graphql' 
    : 'https://mavplusz.hu/otp2-backend/otp/routers/default/index/graphql';

String get photonApiUrl => useProxy 
    ? '$proxyBaseUrl?endpoint=photon' 
    : 'https://mavplusz.hu/photon/api';

String get photonReverseApiUrl => useProxy 
    ? '$proxyBaseUrl?endpoint=photon-reverse' 
    : 'https://mavplusz.hu/photon/reverse';

String get rssApiUrl => useProxy 
    ? '$proxyBaseUrl?endpoint=rss' 
    : 'https://www.mavcsoport.hu/mavinform/rss.xml';

const Map<String, String> apiRequestHeaders = {
	'Content-Type': 'application/json',
	'Dnt': '1',
	'Accept': '*/*',
	'Sec-Ch-Ua':
			'"Google Chrome";v="141", "Chromium";v="141", "Not=A?Brand";v="8"',
	'Sec-Ch-Ua-Mobile': '?1',
	'Sec-Ch-Ua-Platform': '"Android"',
	'User-Agent':
			'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Mobile Safari/537.36',
	'Origin': 'https://mavplusz.hu',
	'Referer': 'https://mavplusz.hu/',
	'Host': 'mavplusz.hu',
	'Connection': 'keep-alive',
	'Sec-Fetch-Dest': 'empty',
	'Sec-Fetch-Mode': 'cors',
};
