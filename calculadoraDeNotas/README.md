# 📊 Grade Calculator

A terminal program in **JavaScript (Node.js)** that calculates a class's grade averages.

## ✨ Features

- Choose the number of students and grades per student
- Each student's average, linked to their name
- Class average
- Highest and lowest averages, with the student's name

## ▶️ How to run

The program uses the `prompt-sync` library to read input from the terminal. From the `calculadoraDeNotas` folder:

```bash
npm install prompt-sync
node calculadora.js
```

## 💻 Example

> The program's interface is in Portuguese, so the example below shows exactly what it prints.

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
