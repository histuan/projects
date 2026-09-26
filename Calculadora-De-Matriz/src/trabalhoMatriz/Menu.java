package trabalhoMatriz;

import java.util.Scanner;
public class Menu {
    //TESTA EXISTENCIA
    boolean matrizExiste(Matrix m){
        if(m == null){
            System.out.println("Crie uma matriz antes!");
            return false;
        }
        return true;
    }
    boolean vetorExiste(Vector v){
        if (v == null) {
            System.out.println("Crie um vetor antes!");
            return false;
        }
        return true;
    }
    boolean escalarExiste(Double e){
        if(e == null){
            System.out.println("Crie um escalar antes!");
            return false;
        }
        return true;
    }
    void interativo(Scanner prompt){

        int opcao = 1;
        int row, col, tamanho;
        Double escalarM = null;
        Double escalarV = null;
        Matrix matrizA = null;
        Matrix matrizB = null;
        Vector vetorA = null;
        Vector vetorB = null;
        LinearAlgebra operacao = new LinearAlgebra();
        while(opcao != 0){
            int opcaoM = 1, opcaoV = 1;
            //TEXTOS DE ENVIO
            System.out.println("Digite 0 se quiser encerrar as operações.");
            System.out.println("1 para operações de matriz.");
            System.out.println("2 para operações de vetor.");
            opcao = prompt.nextInt();

            //OPERACOES DE MATRIZ
            if(opcao == 1) {
                while (opcaoM != 0) {
                    System.out.println("Digite 0 para retornar.");
                    System.out.println("1 para criar sua matriz A principal.");
                    System.out.println("2 para a matriz B secundaria (para operações).");
                    System.out.println("3 para criar o escalar E (para operações).");
                    System.out.println("4 para imprimir a matriz.");
                    System.out.println("5 para realizar transposição de matriz.");
                    System.out.println("6 para somar as matrizes: A + B.");
                    System.out.println("7 para realizar multiplicação elemento por elemento.");
                    System.out.println("8 para realizar multiplicação de matriz por escalar A*E.");
                    System.out.println("9 para realizar multiplicação de matriz A*B");
                    System.out.println("10 para realizar eliminação de Gauss");
                    System.out.println("11 para solucionar a equação.");
                    opcaoM = prompt.nextInt();
                    try {

                        if (opcaoM == 1) {
                            System.out.println("Digite o numero de linhas:");
                            row = prompt.nextInt();
                            System.out.println("Digite o numero de colunas:");
                            col = prompt.nextInt();
                            System.out.printf("Digite os elementos. Total: %d\n", row * col);
                            double[] elementM = new double[row * col];
                            for (int i = 0; i < row * col; i++) {
                                elementM[i] = prompt.nextDouble();
                            }
                            matrizA = new Matrix(row, col, elementM);
                        }

                        if (opcaoM == 2) {
                            System.out.println("Digite o numero de linhas:");
                            row = prompt.nextInt();
                            System.out.println("Digite o numero de colunas:");
                            col = prompt.nextInt();
                            System.out.printf("Digite os elementos. Total: %d\n", row * col);
                            double[] elementM = new double[row * col];
                            for (int i = 0; i < row * col; i++) {
                                elementM[i] = prompt.nextDouble();
                            }
                            matrizB = new Matrix(row, col, elementM);
                        }

                        if (opcaoM == 3) {
                            System.out.println("Digite o escalar:");
                            escalarM = prompt.nextDouble();
                        }

                        if (opcaoM == 4) {
                            if (!matrizExiste(matrizA)) continue;
                            matrizA.imprime();
                        }

                        if (opcaoM == 5) {
                            if (!matrizExiste(matrizA)) continue;
                            Matrix transposta = operacao.transpose(matrizA);
                            transposta.imprime();
                        }

                        if (opcaoM == 6) {
                            if (!matrizExiste(matrizA) || !matrizExiste(matrizB)) continue;
                            Matrix soma = operacao.sum(matrizA, matrizB);
                            soma.imprime();
                        }

                        if (opcaoM == 7) {
                            if (!matrizExiste(matrizA) || !matrizExiste(matrizB)) continue;
                            Matrix mult = operacao.times(matrizA, matrizB);
                            mult.imprime();
                        }

                        if (opcaoM == 8) {
                            if (!matrizExiste(matrizA) || (!escalarExiste(escalarM))) continue;
                            Matrix mult = operacao.times(escalarM, matrizA);
                            mult.imprime();
                        }

                        if (opcaoM == 9) {
                            if (!matrizExiste(matrizA) || !matrizExiste(matrizB)) continue;
                            Matrix mult = operacao.dot(matrizA, matrizB);
                            mult.imprime();
                        }

                        if (opcaoM == 10) {
                            if (!matrizExiste(matrizA)) continue;
                            Matrix gauss = operacao.gauss(matrizA);
                            gauss.imprime();
                        }

                        if (opcaoM == 11) {
                            if (!matrizExiste(matrizA)) continue;
                            Matrix solved = operacao.solve(matrizA);
                            solved.imprime();
                        }
                    }
                    catch(IllegalArgumentException e){
                            System.err.println("\n=== ERRO ===");
                            System.err.println(e.getMessage());
                            System.out.println();
                    }
                }
            }

            //OPERACOES DE VETOR
            if(opcao == 2) {

                while (opcaoV != 0) {
                    System.out.println("Digite 0 para retornar.");
                    System.out.println("1 para criar um vetor A principal.");
                    System.out.println("2 para criar um vetor B secundario(para operações).");
                    System.out.println("3 para criar um escalar E (para operações).");
                    System.out.println("4 para imprimir o vetor.");
                    System.out.println("5 para realizar transposição de vetor.");
                    System.out.println("6 para realizar soma de vetores A+B.");
                    System.out.println("7 para realizar multiplicação de vetores A*B.");
                    System.out.println("8 para realizar multiplicação do vetor por escalar A*E.");
                    opcaoV = prompt.nextInt();

                    if (opcaoV == 1) {
                        System.out.println("Digite o tamanho do vetor.");
                        tamanho = prompt.nextInt();
                        System.out.printf("Digite os elementos. total: %d\n",tamanho);
                        double[] elementV = new double[tamanho];
                        for (int i = 0; i < tamanho; i++) {
                            elementV[i] = prompt.nextDouble();
                        }
                        vetorA = new Vector(tamanho, elementV);
                    }

                    if(opcaoV == 2){
                        System.out.println("Digite o tamanho do vetor.");
                        tamanho = prompt.nextInt();
                        System.out.printf("Digite os elementos. total: %d\n",tamanho);
                        double[] elementV = new double[tamanho];
                        for (int i = 0; i < tamanho; i++) {
                            elementV[i] = prompt.nextDouble();
                        }
                        vetorB = new Vector(tamanho, elementV);
                    }

                    if(opcaoV == 3){
                        System.out.println("Digite o escalar");
                        escalarV = prompt.nextDouble();
                    }

                    if (opcaoV == 4){
                        if (!vetorExiste(vetorA)) continue;
                        vetorA.imprime();
                    }

                    if (opcaoV == 5) {
                        if (!vetorExiste(vetorA)) continue;
                        Matrix vetorTrans = operacao.transpose(vetorA);
                        vetorTrans.imprime();
                    }

                    if(opcaoV == 6){
                        if (!vetorExiste(vetorA) || !vetorExiste(vetorB))  continue;
                        Vector soma = operacao.sum(vetorA, vetorB);
                        soma.imprime();
                    }

                    if(opcaoV == 7){
                        if (!vetorExiste(vetorA) || !vetorExiste(vetorB))  continue;
                        Vector mult = operacao.times(vetorA, vetorB);
                        mult.imprime();
                    }

                    if(opcaoV == 8){
                        if (!vetorExiste(vetorA) || (!escalarExiste(escalarV)))  continue;
                        Vector mult = operacao.times(escalarV, vetorA);
                        mult.imprime();
                    }
                }
            }
        }
    }
}
