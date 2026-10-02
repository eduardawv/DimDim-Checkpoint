package br.com.fiap.clyvo.model.enums;

public enum TipoEvento {


    VACINA(10),
    CONSULTA_ROTINA(5),
    EXAME(5),
    DOENCA_LEVE(-15),
    CIRURGIA(-30),
    DOENCA_GRAVE(-40),
    ACIDENTE(-50),
    RELATO_SINTOMA(-5),
    ALTERACAO_COMPORTAMENTO(-5);

    private final int impactoScore;

    TipoEvento(int impactoScore) {
        this.impactoScore = impactoScore;
    }

    public int getImpactoScore() {
        return impactoScore;
    }

    public int calcularNovoScore(int scoreAtual) {
        int novoScore = scoreAtual + this.impactoScore;
        return Math.max(0, Math.min(100, novoScore));
    }
}
