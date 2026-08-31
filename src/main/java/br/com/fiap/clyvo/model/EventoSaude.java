package br.com.fiap.clyvo.model;

import br.com.fiap.clyvo.model.enums.TipoEvento;
import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;

@Entity
@Table(name = "tb_evento_saude")
public class EventoSaude {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotNull(message = "O pet associado é obrigatório")
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "pet_id", nullable = false)
    private Pet pet;

    @NotNull(message = "O tipo de evento é obrigatório")
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private TipoEvento tipoEvento;

    @NotBlank(message = "A descrição do evento é obrigatória")
    @Column(nullable = false, length = 255)
    private String descricao;

    @NotNull(message = "A data do evento é obrigatória")
    @Column(nullable = false)
    private LocalDate dataEvento;

    public EventoSaude() {
    }

    public EventoSaude(Long id, Pet pet, TipoEvento tipoEvento, String descricao, LocalDate dataEvento) {
        this.id = id;
        this.pet = pet;
        this.tipoEvento = tipoEvento;
        this.descricao = descricao;
        this.dataEvento = dataEvento;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Pet getPet() {
        return pet;
    }

    public void setPet(Pet pet) {
        this.pet = pet;
    }

    public TipoEvento getTipoEvento() {
        return tipoEvento;
    }

    public void setTipoEvento(TipoEvento tipoEvento) {
        this.tipoEvento = tipoEvento;
    }

    public String getDescricao() {
        return descricao;
    }

    public void setDescricao(String descricao) {
        this.descricao = descricao;
    }

    public LocalDate getDataEvento() {
        return dataEvento;
    }

    public void setDataEvento(LocalDate dataEvento) {
        this.dataEvento = dataEvento;
    }
}