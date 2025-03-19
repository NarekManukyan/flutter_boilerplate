enum ReCaptchaAction {
  send_email,
  verify_email,
  auth_mfa_recovery,
  auth_mfa_verify,
  transcript_update,
  generate_notes;

  String get value {
    return switch (this) {
      ReCaptchaAction.send_email => 'send_email',
      ReCaptchaAction.verify_email => 'verify_email',
      ReCaptchaAction.auth_mfa_verify => 'auth_mfa_verify',
      ReCaptchaAction.auth_mfa_recovery => 'auth_mfa_recovery',
      ReCaptchaAction.transcript_update => 'transcript_update',
      ReCaptchaAction.generate_notes => 'generate_notes'
    };
  }
}
