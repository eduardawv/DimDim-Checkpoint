package br.com.fiap.clyvo.service;

import br.com.fiap.clyvo.dto.VeterinarioAuthResponseDTO;
import br.com.fiap.clyvo.dto.VeterinarioLoginRequestDTO;
import br.com.fiap.clyvo.dto.VeterinarioRequestDTO;
import br.com.fiap.clyvo.dto.VeterinarioResponseDTO;
import br.com.fiap.clyvo.exception.AcessoNegadoException;
import br.com.fiap.clyvo.exception.RecursoNaoEncontradoException;
import br.com.fiap.clyvo.model.Veterinario;
import br.com.fiap.clyvo.repository.VeterinarioRepository;
import br.com.fiap.clyvo.security.CustomUserDetails;
import br.com.fiap.clyvo.security.JwtService;
import br.com.fiap.clyvo.security.AuthUser;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class VeterinarioService {

    private final VeterinarioRepository repository;
    private final JwtService jwtService;
    private final PasswordEncoder passwordEncoder;
    private final AuthUser authUser;

    public VeterinarioService(
            VeterinarioRepository repository,
            JwtService jwtService,
            PasswordEncoder passwordEncoder,
            AuthUser authUser
    ) {
        this.repository = repository;
        this.jwtService = jwtService;
        this.passwordEncoder = passwordEncoder;
        this.authUser = authUser;
    }


    private void validarEscritaDoVeterinario(Long id) {
        if (!authUser.isVeterinario()
                || !id.equals(authUser.getId())) {
            throw new AcessoNegadoException(
                    "Você só pode alterar a sua própria conta.");
        }
    }

    private VeterinarioResponseDTO toResponse(Veterinario veterinario) {
        return new VeterinarioResponseDTO(
                veterinario.getId(),
                veterinario.getNome(),
                veterinario.getEmail(),
                veterinario.getCrmv()
        );
    }

    @Transactional
    public VeterinarioResponseDTO cadastrar(VeterinarioRequestDTO dto) {

        if (repository.findByEmail(dto.email()).isPresent()) {
            throw new RuntimeException("E-mail já cadastrado no sistema!");
        }

        if (repository.findByCrmv(dto.crmv()).isPresent()) {
            throw new RuntimeException("CRMV já cadastrado no sistema!");
        }

        Veterinario veterinario = new Veterinario();

        veterinario.setNome(dto.nome());
        veterinario.setEmail(dto.email());
        veterinario.setCrmv(dto.crmv());
        veterinario.setSenha(passwordEncoder.encode(dto.senha()));

        veterinario = repository.save(veterinario);

        return toResponse(veterinario);
    }

    public VeterinarioAuthResponseDTO autenticar(VeterinarioLoginRequestDTO dto) {

        Veterinario veterinario = repository.findByEmail(dto.email())
                .orElseThrow(() -> new RuntimeException("E-mail ou senha inválidos."));

        if (!passwordEncoder.matches(dto.senha(), veterinario.getSenha())) {
            throw new RuntimeException("E-mail ou senha inválidos.");
        }

        CustomUserDetails userDetails = new CustomUserDetails(
                veterinario.getId(),
                veterinario.getNome(),
                veterinario.getEmail(),
                veterinario.getSenha(),
                "VETERINARIO"
        );

        String token = jwtService.gerarToken(userDetails);

        return new VeterinarioAuthResponseDTO(
                veterinario.getId(),
                veterinario.getNome(),
                veterinario.getEmail(),
                veterinario.getCrmv(),
                "VETERINARIO",
                token
        );
    }

    public Page<VeterinarioResponseDTO> listar(Pageable paginacao) {
        return repository.findAll(paginacao).map(this::toResponse);
    }

    public VeterinarioResponseDTO buscarPorId(Long id) {

        Veterinario veterinario = repository.findById(id)
                .orElseThrow(() -> new RecursoNaoEncontradoException(
                        "Veterinário não encontrado com o ID: " + id));

        return toResponse(veterinario);
    }


    @Transactional
    public VeterinarioResponseDTO atualizar(Long id, VeterinarioRequestDTO dto) {

        validarEscritaDoVeterinario(id);

        Veterinario veterinario = repository.findById(id)
                .orElseThrow(() -> new RecursoNaoEncontradoException(
                        "Veterinário não encontrado com o ID: " + id));

        veterinario.setNome(dto.nome());
        veterinario.setEmail(dto.email());
        veterinario.setCrmv(dto.crmv());

        if (dto.senha() != null && !dto.senha().isBlank()) {
            veterinario.setSenha(passwordEncoder.encode(dto.senha()));
        }

        veterinario = repository.save(veterinario);

        return toResponse(veterinario);
    }


    @Transactional
    public void excluir(Long id) {

        validarEscritaDoVeterinario(id);

        Veterinario veterinario = repository.findById(id)
                .orElseThrow(() -> new RecursoNaoEncontradoException(
                        "Veterinário não encontrado com o ID: " + id));

        repository.delete(veterinario);
    }
}
