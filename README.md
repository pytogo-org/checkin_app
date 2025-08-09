# PyCon Togo Check-in App

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Flutter mobile application for attendee check-in at PyCon Togo events via QR code scanning.

## Prerequisites

- Flutter SDK (version 3.0 or higher)
- A deployed backend (fork our [PyCon Togo API](https://github.com/pytogo-org/pycontg-api))

## Installation

1. Fork and clone this repository
2. Add your organization's logo:
   - Create an `assets/logos` folder at the project root
   - Place your logo named `logo.png` inside
   - OR modify the `_logo` variable in `lib/screens/login_screen.dart` to point to your logo (local file or URL)
3. Configure the API base URL in `lib/constants.dart`
4. Run `flutter pub get` to install dependencies

## Features

- Organizer authentication
- QR code scanning for check-in
- Check-in results display
- Automatic theme based on your logo's dominant color

## Contributing

Contributions are welcome! Please open an issue to discuss proposed changes before submitting a pull request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
