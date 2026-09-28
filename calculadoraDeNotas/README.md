# Grade Calculator

Terminal program in JavaScript (Node.js) that calculates grade averages for a class.

## Features

- Choose how many students and how many grades per student
- Average for each student, linked to their name
- Class average
- Highest and lowest averages, with the student's name

## How to run

The program reads input with the `prompt-sync` library. From the `calculadoraDeNotas` folder:

```bash
npm install prompt-sync
node calculadora.js
```

## Example

The interface is in Portuguese, so this is exactly what the program prints.

Input:

```
quantidade de alunos na sala: 2
quantidade de notas por aluno: 2
nome do aluno: Ana
1º nota: 8
2º nota: 9
nome do aluno: Bruno
1º nota: 6
2º nota: 7
```

Output:

```
====================================
aluno: Ana => media: 8.50
aluno: Bruno => media: 6.50
media geral: 7.50
maior media: 8.5 => Ana
menor media: 6.5 => Bruno
====================================
```
