component {

	property name="cacheStorage" 	inject="cacheStorage@cbstorages";

	function preHandler(event,rc,prc){
		prc.facebookSettings = getModuleSettings('nsg-module-facebook')['oauth'];
		param name="prc.facebookSettings['fields']" default="name,email,first_name,last_name";
		if( !cacheStorage.exists( 'facebookOAuth' ) ){
			cacheStorage.setVar( 'facebookOAuth', structNew() );
		}
	}

	function index(event,rc,prc){
		flash.keep();
		if( event.getValue('id','') == 'activateUser' ){
			var results = duplicate( cacheStorage.getVar( 'facebookOAuth', structNew() ) );
			
			// convert expires into a useful date/time
			results['expiresAt'] = createODBCDateTime(now()+results['expires_in']/60/60/24);	

			var httpService = new http();
				httpService.setURL('https://graph.facebook.com/me?fields=#prc.facebookSettings['fields']#&client_id=#prc.facebookSettings['appID']#&client_secret=#prc.facebookSettings['appSecret']#&access_token=#results['access_token']#');
			var data = deserializeJSON(httpService.send().getPrefix()['fileContent']);
			structAppend(results,data);

			structKeyRename(results,'id','referenceID');
			if( structKeyExists( results,'first_name' ) ){
				structKeyRename(results,'first_name','first');
			} else {
				param name="results.first" default="";  	
			}
			if( structKeyExists( results,'last_name' ) ){
				structKeyRename(results,'last_name','last');
			} else {
				param name="results.last" default="";  	
			}
			param name="results.email" default="";

			results['socialservice'] = 'facebook';

			announceInterception( state='facebookLoginSuccess', interceptData=results );
			announceInterception( state='loginSuccess', interceptData=results );
			setNextEvent(view=prc.facebookSettings['loginSuccess'],ssl=( cgi.server_port == 443 ? true : false ));

		}else if( event.valueExists('code') ){
			results = cacheStorage.getVar( 'facebookOAuth' );
			results['code'] = event.getValue('code');

			var httpService = new http();
				httpService.setURL('#prc.facebookSettings['tokenRequestURL']#?client_id=#prc.facebookSettings['appID']#&redirect_uri=#urlEncodedFormat(prc.facebookSettings['redirectURL'])#&client_secret=#prc.facebookSettings['appSecret']#&code=#results['code']#');
			var results = httpService.send().getPrefix();
			if( results['status_code'] == 200 ){
				var myFields = listToArray(results['fileContent'],'&');
				myFields = deserializeJSON( results['fileContent'] );
				structAppend( results, myFields );
				cacheStorage.setVar( 'facebookOAuth', results );
				setNextEvent('facebook/oauth/activateUser');
			}else{
				announceInterception( state='facebookLoginFailure', interceptData=results );
				announceInterception( state='loginFailure', interceptData=results );
				throw('Unknown Facebook OAuth.v2 Error','facebook.oauth');
			}

		}else{

			location(url="#prc.facebookSettings['authorizeRequestURL']#?client_id=#prc.facebookSettings['appID']#&redirect_uri=#urlEncodedFormat(prc.facebookSettings['redirectURL'])#&scope=#prc.facebookSettings['scope']#&response_type=#prc.facebookSettings['responseType']#",addtoken=false);
		}
	}

	function structKeyRename(mStruct,mTarget,mKey){
		arguments.mStruct[mKey] = arguments.mStruct[mTarget];
		structDelete(arguments.mStruct,mTarget);

		return arguments.mStruct;
	}
}
