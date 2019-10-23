/// An exception for type conversion errors
class InvalidTypeException implements Exception {
  /// Provide a message
  InvalidTypeException(this.message);

  /// The error message
  final String message;
}

/// An exception for unknown values
class UnknownValueException implements Exception {
  /// Provide a message
  UnknownValueException(this.message);

  /// The error message
  final String message;
}

/// An exception for wrong values
class WrongWalueTypeException implements Exception {
  /// Provide a message
  WrongWalueTypeException(this.message);

  /// The error message
  final String message;
}

/// An exception for decoding errors
class DecodingException implements Exception {
  /// Provide a message
  DecodingException(this.message);

  /// The error message
  final String message;
}

/// An exception for encoding errors
class EncodingException implements Exception {
  /// Provide a message
  EncodingException(this.message);

  /// The error message
  final String message;
}
