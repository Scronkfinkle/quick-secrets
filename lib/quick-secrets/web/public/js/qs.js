// console.log("Loading quick-secrets.js");

var qs = (() => {
  console.log("Loading quick-secrets.js");

  // Validate the value of a form field (:id),
  // checking validity via predicate function (:validate_fn).
  // If predicate passes, return value, and mark input field as "valid".
  // If predicate fails, return `null`, and mark input field as "invalid".
  validate_field = function(id, validate_fn){
    let field = `#${id}`;
    let value = $(field).val();
    let valid = validate_fn(value);
    $(field).toggleClass("is-invalid", !valid);
    // also toggle the "Help" for that field:
    $(`${field}Help`).toggle(!valid);
    console.log(`${id} == '${value}' (${valid})`)
    return (valid ? value : null);
  }

  // return true if `val` is a non-empty string
  is_empty_string = function(val){
    // cheater - both null and empty string return false
    return ! val
    // better way:
    // return (val === undefined || val == null || val.length <= 0);
  }

  is_non_empty_string = function(str){
    return ! is_empty_string(str);
  }

  // check that the argument is a 'valid' username.
  is_valid_username = function(pass){
    return (is_non_empty_string(pass) && pass.length >= 5);
  }

  // return human readable description of the complexity rules for usernames.
  username_complexity_description = function() {
    return "Must be at least 5 characters long.";
  }

  // check that the argument is a 'valid' password/passphrase,
  // passing required complexity checks.
  is_valid_password = function(pass){
    return (is_non_empty_string(pass) && pass.length >= 7);
  }

  // return human readable description of the complexity rules for passwords/passphrases.
  password_complexity_description = function() {
    return "Must be at least 7 characters long.";
  }

  xyzzy = function() {
    return "nothing happens.";
  }

  return {
    validate_field,
    is_empty_string,
    is_non_empty_string,
    is_valid_username,
    username_complexity_description,
    is_valid_password,
    password_complexity_description,
    xyzzy
  }


})()
