package com.mongodb.stitch.android.tutorials.todo;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.support.annotation.NonNull;
import android.support.v7.app.AppCompatActivity;
import android.util.Log;
import android.view.View;
import android.widget.Toast;

import com.facebook.AccessToken;
import com.facebook.CallbackManager;
import com.facebook.FacebookCallback;
import com.facebook.FacebookException;
import com.facebook.login.LoginManager;
import com.facebook.login.LoginResult;
import com.google.android.gms.auth.api.signin.GoogleSignIn;
import com.google.android.gms.auth.api.signin.GoogleSignInAccount;
import com.google.android.gms.auth.api.signin.GoogleSignInClient;
import com.google.android.gms.auth.api.signin.GoogleSignInOptions;

import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.api.ApiException;
import com.google.android.gms.common.api.GoogleApiClient;
import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.Task;
import com.mongodb.stitch.android.core.auth.StitchUser;
import com.mongodb.stitch.android.tutorials.todo.R;
import com.mongodb.stitch.core.auth.providers.facebook.FacebookCredential;
import com.mongodb.stitch.core.auth.providers.google.GoogleCredential;

import com.facebook.FacebookSdk;

import java.util.Arrays;

import static com.google.android.gms.auth.api.Auth.GOOGLE_SIGN_IN_API;

public class LogonActivity extends AppCompatActivity {

    private CallbackManager _callbackManager;
    private GoogleApiClient _googleApiClient;
    private static final int RC_SIGN_IN = 421;
    private Boolean _fbInitOnce = false;

    @Override
    protected void onCreate(final Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        FacebookSdk.sdkInitialize(getApplicationContext());

        setContentView(R.layout.logon);
        setupLogin();
    }

    private void setupLogin() {

        final String facebookAppId = getString(R.string.facebook_app_id);
        final String googleWebClientId = getString(R.string.google_web_client_id);

        setContentView(R.layout.logon);

        enableFacebookAuth(facebookAppId);
        enableGoogleAuth(googleWebClientId);
    }

    private void enableGoogleAuth(String googleWebClientId) {
        final GoogleSignInOptions.Builder gsoBuilder = new GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
                .requestServerAuthCode(googleWebClientId, true);

        final GoogleSignInOptions gso = gsoBuilder.build();

        _googleApiClient = new GoogleApiClient.Builder(LogonActivity.this)
                .enableAutoManage(LogonActivity.this, new GoogleApiClient.OnConnectionFailedListener() {
                    @Override
                    public void onConnectionFailed(@NonNull ConnectionResult connectionResult) {
                        Log.e("Stitch Auth", "Error connecting to google: " + connectionResult.getErrorMessage());
                    }
                })
                .addApi(GOOGLE_SIGN_IN_API, gso)
                .build();

        findViewById(R.id.google_login_button).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(final View ignored) {

                GoogleSignInOptions gso = new GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
                        .requestServerAuthCode(googleWebClientId)
                        .build();
                GoogleSignInClient mGoogleSignInClient = GoogleSignIn.getClient(LogonActivity.this, gso);

                Intent signInIntent = mGoogleSignInClient.getSignInIntent();
                startActivityForResult(signInIntent, RC_SIGN_IN);
            }
        });
    }

    private void enableFacebookAuth(String facebookAppId) {
        if (!facebookAppId.equals("TBD")) {
            findViewById(R.id.fb_login_button).setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(final View ignored) {

                    // Check if already logged in
                    if (AccessToken.getCurrentAccessToken() != null) {

                        final FacebookCredential fbCredential = new FacebookCredential(AccessToken.getCurrentAccessToken().getToken());
                        TodoListActivity.client.getAuth().loginWithCredential(fbCredential).addOnCompleteListener(new OnCompleteListener<StitchUser>() {
                            @Override
                            public void onComplete(@NonNull final Task<StitchUser> task) {
                                if (task.isSuccessful()) {
                                    _fbInitOnce = true;
                                    setResult(Activity.RESULT_OK);
                                    finish();
                                    //initTodoView();
                                } else {
                                    Log.e("Stitch Auth", "Error logging in with Facebook", task.getException());
                                }
                            }
                        });
                        return;
                    }

                    _callbackManager = CallbackManager.Factory.create();
                    LoginManager.getInstance().registerCallback(_callbackManager,
                            new FacebookCallback<LoginResult>() {
                                @Override
                                public void onSuccess(LoginResult loginResult) {
                                    final FacebookCredential fbCredential = new FacebookCredential(AccessToken.getCurrentAccessToken().getToken());

                                    TodoListActivity.client.getAuth().loginWithCredential(fbCredential).addOnCompleteListener(new OnCompleteListener<StitchUser>() {
                                        @Override
                                        public void onComplete(@NonNull final Task<StitchUser> task) {
                                            if (task.isSuccessful()) {
                                                _fbInitOnce = true;
                                                setResult(Activity.RESULT_OK);
                                                finish();
                                                //initTodoView();
                                            } else {
                                                Log.e("Stitch Auth", "Error logging in with Facebook",
                                                        task.getException());
                                            }
                                        }
                                    });
                                }

                                @Override
                                public void onCancel() {
                                    Toast.makeText(LogonActivity.this, "Facebook logon was " +
                                            "cancelled.", Toast.LENGTH_LONG).show();
                                }

                                @Override
                                public void onError(final FacebookException exception) {
                                    Toast.makeText(LogonActivity.this, "Failed to logon with " +
                                            "Facebook. Result: " + exception.toString(), Toast.LENGTH_LONG).show();

                                }
                            });
                    LoginManager.getInstance().logInWithReadPermissions(
                            LogonActivity.this,
                            Arrays.asList("public_profile"));
                }
            });
        }
    }

    private void handleGoogleSignInResult(Task<GoogleSignInAccount> completedTask) {
        try {
            GoogleSignInAccount account = completedTask.getResult(ApiException.class);

            final GoogleCredential googleCredential =
                    new GoogleCredential(account.getServerAuthCode());

            TodoListActivity.client.getAuth().loginWithCredential(googleCredential).addOnCompleteListener(
                    task -> {
                        if (task.isSuccessful()) {
                            setResult(Activity.RESULT_OK);
                            finish();
                        } else {
                            Log.e("Stitch Auth", "Error logging in with Google", task.getException());
                        }
                    });
        } catch (ApiException e) {
            Log.w("GOOGLE AUTH FAILURE", "signInResult:failed code=" + e.getStatusCode());
            setResult(Activity.RESULT_CANCELED);
            finish();
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);

        if (requestCode == RC_SIGN_IN) {
            Task<GoogleSignInAccount> task = GoogleSignIn.getSignedInAccountFromIntent(data);
            handleGoogleSignInResult(task);
            return;
        }

        if (_callbackManager != null) {
            _callbackManager.onActivityResult(requestCode, resultCode, data);
            return;
        }

        Log.e("Stitch Auth", "Nowhere to send activity result for ourselves");
    }
}
