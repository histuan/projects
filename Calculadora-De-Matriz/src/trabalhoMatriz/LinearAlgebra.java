package trabalhoMatriz;

public class LinearAlgebra {

    //REALIZA TRASNPOSIÇÃO DA MATRIZ
    public Matrix transpose(Matrix m) {

        int linhas = m.getRows(), colunas = m.getCols();
        Matrix matrizT = new Matrix(colunas, linhas, null);

        for (int i = 0; i < linhas; i++) {
            for (int j = 0; j < colunas; j++) {

                matrizT.set(j, i, m.get(i, j));

            }
        }
        return matrizT;
    }

    //REALIZA TRANSPOSIÇÃO DO VETOR
    public Matrix transpose(Vector v) {

        int tamanho = v.getDim();

        Matrix vetorT = new Matrix(tamanho, 1, null);
        for (int i = 0; i < tamanho; i++) {
            vetorT.set(i, 0, v.get(i));
        }
        return vetorT;
    }

    //REALIZA SOMA DE MATRIZES
    public Matrix sum(Matrix a, Matrix b) {
        int linhasA = a.getRows(), colunasA = a.getCols();
        int linhasB = b.getRows(), colunasB = b.getCols();
        if (linhasA != linhasB || colunasA != colunasB) {
            throw new IllegalArgumentException("IMPOSSIVEL - As matrizes são de dimensões diferentes.");
        }

        Matrix c = new Matrix(linhasA, colunasA, null);
        for (int i = 0; i < linhasA; i++) {
            for (int j = 0; j < colunasA; j++) {
                c.set(i, j, a.get(i, j) + b.get(i, j));
            }
        }
        return c;
    }

    //REALIZA SOMA DE VETORES
    public Vector sum(Vector a, Vector b) {

        int tamanhoA = a.getDim(), tamanhoB = b.getDim();

        if (tamanhoA != tamanhoB) {
            throw new IllegalArgumentException("IMPOSSIVEL - Os vetores são de dimensões diferentes.");
        }
        Vector c = new Vector(tamanhoA, null);
        for (int i = 0; i < tamanhoA; i++) {
            c.set(i, a.get(i) + b.get(i));
        }
        return c;
    }

    //REALIZA MULTIPLICAÇÃO DE MATRIZES ELEMENTO A ELEMENTO
    public Matrix times(Matrix a, Matrix b) {

        int linhasA = a.getRows(), colunasA = a.getCols();
        int linhasB = b.getRows(), colunasB = b.getCols();
        if (linhasA != linhasB || colunasA != colunasB) {
            throw new IllegalArgumentException("IMPOSSIVEL - As matrizes são de dimensões diferentes.");
        }

        Matrix c = new Matrix(a.getRows(), a.getCols(), null);
        for (int i = 0; i < a.getRows(); i++) {
            for (int j = 0; j < a.getCols(); j++) {
                c.set(i, j, a.get(i, j) * b.get(i, j));
            }
        }
        return c;
    }

    //REALIZA MULTIPLICAÇÃO DE MATRIZ COM ESCALAR
    public Matrix times(double a, Matrix b) {

        int linhasB = b.getRows(), colunasB = b.getCols();
        Matrix c = new Matrix(linhasB, colunasB, null);
        for (int i = 0; i < linhasB; i++) {
            for (int j = 0; j < colunasB; j++) {
                c.set(i, j, b.get(i, j) * a);
            }
        }
        return c;
    }

    //REALIZA MULTIPLICAÇÃO DE VETORES
    public Vector times(Vector a, Vector b) {

        int tamanhoA = a.getDim(), tamanhoB = b.getDim();

        if (tamanhoA != tamanhoB) {
            throw new IllegalArgumentException("IMPOSSIVEL - O tamanho dos vetores são diferentes.");
        }

        Vector c = new Vector(tamanhoA, null);
        for (int i = 0; i < a.getDim(); i++) {
            c.set(i, a.get(i) * b.get(i));
        }
        return c;
    }

    //REALIZA MULTIPLICAÇÃO DE VETOR POR ESCALAR
    public Vector times(double a, Vector b){

        int tamanho = b.getDim();

        Vector c = new Vector(tamanho,null);
        for(int i = 0; i<tamanho; i++){
            c.set(i,b.get(i) * a);
        }
        return c;
    }


    //REALIZA MULTIPLICAÇÃO DE MATRIZES
    public Matrix dot(Matrix a, Matrix b) {
        int linhasA = a.getRows(), colunasA = a.getCols();
        int linhasB = b.getRows(), colunasB = b.getCols();
        if (colunasA != linhasB) {
            throw new IllegalArgumentException("IMPOSSIVEL - A numero de colunas de 'A' é diferente do numero de linhas de 'B'.");
        }

        Matrix c = new Matrix(linhasA, colunasB, null);
        for (int i = 0; i < linhasA; i++) {
            for (int j = 0; j < colunasB; j++) {
                for (int k = 0; k < colunasA; k++) {
                    c.set(i, j, c.get(i, j) + a.get(i, k) * b.get(k, j));
                }
            }
        }
        return c;
    }


    //REALIZA ELIMINAÇÃO DE GAUSS
    public Matrix gauss(Matrix a) {

        int linhas = a.getRows(), colunas = a.getCols();
        double fator;

        Matrix b = new Matrix(linhas, colunas, null);

        for (int i = 0; i < linhas; i++) {
            for (int j = 0; j < colunas; j++) {
                b.set(i, j, a.get(i, j));
            }
        }

        //pivoteamento
        for (int p = 0; p < Math.min(linhas, colunas); p++) {
            if (Math.abs(b.get(p, p)) < 1e-9) {
                boolean achou = false;
                for (int k = p + 1; k < linhas; k++) {
                    if (Math.abs(b.get(k, p)) > 1e-9) {
                        b.trocarLinhas(k, p);
                        achou = true;
                        break;
                    }
                }
                if (!achou) continue;
            }

            //eliminação
            for (int i = p + 1; i < linhas; i++) {
                fator = b.get(i, p) / b.get(p, p);

                for (int j = p; j < colunas; j++) {
                    b.set(i, j, b.get(i, j) - fator * b.get(p, j));

                }
            }
        }
        return b;
    }


    //SOLUCIONA A MATRIZ
    public Matrix solve(Matrix a) {

        int linhas = a.getRows(), colunas = a.getCols();
        if(colunas != linhas+1){
            throw new IllegalArgumentException("IMPOSSIVEL - a matriz não está no formato de ampliada.");
        }
        double fator;
        boolean indeterminado = false;

        Matrix escalonada = gauss(a);

        //teste de possibilidade
        for (int i = 0; i < linhas; i++) {
            if (Math.abs(escalonada.get(i, i)) < 1e-9) {

                if (Math.abs(escalonada.get(i, colunas-1)) > 1e-9) {

                    throw new IllegalArgumentException("IMPOSSIVEL.");
                } else {
                    indeterminado = true;
                }
            }
        }
        if(indeterminado){
            throw new IllegalArgumentException("POSSIVEL INDETERMINADO.");
        }
        //Gauss - Jordan

        for(int p = linhas-1; p>=0; p-- ){

            double pivo = escalonada.get(p,p);
            for(int k = p; k<colunas; k++){
                escalonada.set(p,k, escalonada.get(p,k) / pivo);
            }
            for(int i = p-1;i>=0;i--){
                fator = escalonada.get(i,p);

                for(int j = p; j<colunas; j++){
                    escalonada.set(i, j, escalonada.get(i,j) - (fator * escalonada.get(p,j)));
                }
            }
        }
        //retorna as raizes
        Matrix raizes = new Matrix(linhas,1,null);
        for(int i = 0; i<linhas; i++){
            raizes.set(i,0,escalonada.get(i,colunas-1));
        }

        return raizes;
    }
}





