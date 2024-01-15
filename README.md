# Enigma Machine Simulator in x86 Assembly

Experience the historical Enigma machine in action with this meticulously crafted console-based simulator written in x86 Assembly, tailored for the 8086 microprocessor.

## 📌 Table of Contents

- [Features](#features)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Running the Simulator](#running-the-simulator)
- [Code Structure](#code-structure)
- [Acknowledgments](#acknowledgments)
- [Credits](#credits)
- [License](#license)
- [About the Author](#about-the-author)

## 🎛️ Features

- Accurate simulation of the Enigma machine's core components.
- Customizable configuration for rotors, reflectors, and initial settings.
- User-friendly interface for input and output.
- Realistic rotor cycling, turnover, and encryption/decryption process.
- Emulation of historical Enigma settings.

## 🚀 Getting Started

### Prerequisites

Ensure you have the following tools installed:

- NASM
- DOSBOX for emulation of 8086

### Running the Simulator

1. Compile the assembly code:

```
nasm enigma.asm -o enigma.com
```

2. Execute the compiled output:

```
enigma.com
```

## 🔍 Code Structure

The Enigma machine simulator is structured for clarity and ease of understanding:

- **Data Section**: Contains configurations, rotor settings, and messages.
- **Code Section**: Houses the Enigma machine simulation logic, rotor cycling, and encryption/decryption processes.

## 🤝 Acknowledgments

Special thanks to all contributors and enthusiasts who have shared insights into the Enigma machine and its historical significance.

## 🎓 Credits

- **Cory Lutton**
  - For inspiring ideas and logic in the Enigma machine simulation. Visit [Cory Lutton's Enigma in C](http://corylutton.com/enigma-c.html).

## 📜 License

This project is open-source under the MIT License. Refer to the [LICENSE](./LICENSE) file for details.

## 👤 About the Author

**Zohaibanwer984**: Aspiring coder and history buff. Enjoys unraveling the complexities of assembly language. Connect on GitHub: [@zohaibanwer984](https://github.com/zohaibanwer984)