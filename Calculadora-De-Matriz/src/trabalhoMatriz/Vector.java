package trabalhoMatriz;

public class Vector {
    private int dim;
    private double[] elements;

    //CONSTRUTOR
    public Vector(int dim, double[] elements){
        this.dim = dim;
        this.elements = new double[dim];
        if(elements != null){
            for(int i = 0; i<dim; i++) {
                this.elements[i] = elements[i];
            }
        }
    }

    //GETTER
    public int getDim(){
        return this.dim;
    }

    //FUNÇÕES GET E SET I
    public void set(int i, double value){
        if(i >= this.dim || i < 0) throw new IllegalArgumentException ("IMPOSSIVEL - Posição inexistente.");
        else this.elements[i] = value;
    }
    public double get(int i){
        if(i >= this.dim || i < 0){
            throw new IllegalArgumentException ("IMPOSSIVEL - Posição inexistente.");
        }
        else return this.elements[i];
    }

    public void imprime(){
        System.out.println("");
        for(int i = 0; i<dim; i++){
            if(i == dim-1) System.out.printf("%.1f\n\n",elements[i]);
            else System.out.printf("%.1f ",elements[i]);
        }
    }
}
