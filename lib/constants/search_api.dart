// Kereső API endpoint konstans
const String searchApiUrl = 'https://mavplusz.hu/otp2-backend/otp/routers/default/geocode/stations';
const String planApiUrl = 'https://mavplusz.hu/otp2-backend/otp/routers/default/index/graphql';

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
