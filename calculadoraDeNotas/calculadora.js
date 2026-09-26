//pra ser ultilizado apenas em locais onde o prompt nao é aceito
const prompt = require('prompt-sync')();
//declaração de variaveis e cabecalho
function fn(){
    console.log("====================================")
}
var nome = [], notas = [], media = [], total = 0, media1 = 0, mediageral = 0, maiorm = 0, menorm = 0;
//entrada de dados
fn();
var qtd = Number(prompt("quantidade de alunos na sala: "));
var n = Number(prompt("quantidade de notas por aluno: "));
for (i = 0; i<qtd; i++){
    nome[i] = prompt("nome do aluno: ");
    for(l = 1; l<n+1;l++){
    notas[i+qtd*l] = Number(prompt((l)+"º nota: "));;
    media1 += notas[i+qtd*l];
    }
    media[i] = ((media1)/n);
    total += media[i];
    media1 = 0;
}
//saida de dados
console.clear();
fn();
for (i = 0; i<qtd; i++){
    console.log("aluno: "+nome[i]+" => media: "+media[i].toFixed(2));
}
mediageral = (total)/qtd;
console.log("media geral: "+mediageral.toFixed(2)) ;
console.log("maior media: "+Math.max(...media)+" => "+nome[media.indexOf(Math.max(...media))]);
console.log("menor media: "+Math.min(...media)+" => "+nome[media.indexOf(Math.min(...media))]);
fn();
