package trabalhoMatriz;

import java.util.Locale;
import java.util.Scanner;

public class Main {
    public static void main(String[] args){
        Scanner prompt = new Scanner(System.in);
        prompt.useLocale(Locale.US);
        Menu menu = new Menu();
        menu.interativo(prompt);
        System.out.println("Até a proxima!");
        prompt.close();
    }
}
