# Matrix and Linear Systems Calculator

Java program that runs linear algebra operations on matrices and vectors from the terminal.

## Features

- Matrix and vector addition and multiplication
- Transposition
- Gaussian elimination
- Solving linear systems
- Interactive menu to move between operations
- Error handling for invalid input

## Code organization

```
src/trabalhoMatriz/
├── Main.java            # entry point
├── Menu.java            # user interaction
├── Matrix.java          # matrix representation
├── Vector.java          # vector representation
└── LinearAlgebra.java   # the operations
```

## How to run

From the `Calculadora-De-Matriz` folder:

```bash
javac -d out src/trabalhoMatriz/*.java
java -cp out trabalhoMatriz.Main
```

The program's interface is in Portuguese.
