Coldbox Module to allow Social Login via Facebook
================

Setup & Installation
---------------------

####Add the following structure to Coldbox.cfc

    facebook = {
        oauth = {
            redirectURL     = "http://www.nextstep.guru/facebook/oauth",
            loginSuccess    = "login.success",
            loginFailure    = "login.failure",
            appID           = "123456789",
            appSecret       = "987654321",
            scope           = "public_profile,email,user_friends",
            fields			= "name,email,first_name,last_name",
            responseType    = "code",   
			oauthVersion 		= 2,
			authorizeRequestURL = "https://www.facebook.com/dialog/oauth",
			tokenRequestURL 	= "https://graph.facebook.com/oauth/access_token"
        }
    }

Interception Point
---------------------
If you want to capture any data from a successful login, use the interception point twitterLoginSuccess. Inside the interceptData structure will contain all the provided data from twitter for the specific user.

####An example interception could look like this

    component {
        function facebookLoginSuccess(event,interceptData){
            var queryService = new query(sql="SELECT roles,email,password FROM user WHERE facebookUserID = :id;");
                queryService.addParam(name="id",value=interceptData['id']);
            var lookup = queryService.execute().getResult();
            if( lookup.recordCount ){
                login {
                    loginuser name=lookup.email password=lookup.password roles=lookup.roles;
                };
            }else{
                // create new user
            }
        }
    }

