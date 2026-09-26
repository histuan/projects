package trabalhoMatriz;

public class Matrix {
    private int rows;
    private int cols;
    private double[][] elements;

    //CONSTRUTOR
    public Matrix(int rows, int cols, double[] elements){
        if(rows <= 0 || cols <= 0) {
            throw new IllegalArgumentException("INVALIDO - linha ou coluna menor ou igual a zero.");
        }
        if(elements != null && elements.length != rows*cols) {
            throw new IllegalArgumentException("INVALIDO - array com menos argumentos que possivel.");
        }
        this.rows = rows;
        this.cols = cols;
        this.elements = new double[rows][cols];
        if(elements != null){
            for(int i =0; i<this.rows; i++){
                for(int j = 0; j<this.cols; j++) {
                    this.elements[i][j] = elements[i * cols + j];
                }
            }
        }
    }

    //GETTERS

    public int getRows(){
        return this.rows;
    }
    public int getCols(){
        return this.cols;
    }

    //FUNÇÕES GET E SET I & J
    public void set(int i, int j, double value){
        if(i >= rows || 0 > i|| j >= cols || 0 > j){
            throw new IllegalArgumentException ("IMPOSSIVEL - Posição inexistente.");
        }
        else this.elements[i][j] = value;
    }
    public double get(int i,int j){
        if(i >= rows || 0 > i || j >= cols ||  0 > j) {
            throw new IllegalArgumentException ("IMPOSSIVEL - Posição inexistente.");
        }
        else return this.elements[i][j];
    }
    public double[] getLinha(int i){
        if(i >= rows || 0 > i) {
            throw new IllegalArgumentException ("IMPOSSIVEL - Posição inexistente.");
        }
        double[] copia = new double[cols];
        for(int k = 0; k<cols; k++){
            copia[k] = elements[i][k];
        }
        return copia;
    }
    public double[] getColuna(int j){
        if(j >= cols ||  0 > j) {
            throw new IllegalArgumentException ("IMPOSSIVEL - Posição inexistente.");
        }
        double[] copia = new double[rows];
        for(int k = 0; k<rows; k++){
            copia[k] = elements[k][j];
        }
        return copia;
    }

    public void trocarLinhas(int i, int k){
        if(i >= rows || 0 > i|| k >= rows || 0 > k){
            throw new IllegalArgumentException ("IMPOSSIVEL - Posição inexistente.");
        }
        double[] aux = this.elements[i];
        this.elements[i] = this.elements[k];
        this.elements[k] = aux;
    }

    public void imprime(){
        System.out.println("");
        for(int i = 0; i<rows; i++){
            for(int j = 0; j<cols; j++){
                if(j == cols-1) System.out.printf("%.1f\n",this.elements[i][j]);
                else System.out.printf("%.1f ",this.elements[i][j]);
            }
        }
        System.out.println("");
    }
}
