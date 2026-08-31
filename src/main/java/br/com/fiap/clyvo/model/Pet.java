package br.com.fiap.clyvo.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "TB_PET")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class Pet {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank(message = "O nome do pet é obrigatório")
    @Column(nullable = false, length = 100)
    private String nome;

    @NotBlank(message = "A espécie é obrigatória")
    @Column(nullable = false, length = 50)
    private String especie; // Ex: Cão, Gato

    @Column(length = 50)
    private String raca;

    @NotNull(message = "A idade é obrigatória para calcular o período de check-up")
    private Integer idade;

    @NotNull(message = "O peso é essencial para a dosagem de vermífugos")
    private Double peso;

    // A famosa "Barra de Vida" do projeto de vocês!
    @Column(name = "health_score", nullable = false)
    private Integer healthScore = 100;

    // Relacionamento: Vários Pets podem pertencer a 1 Tutor
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "tutor_id", nullable = false)
    private Tutor tutor;
}
