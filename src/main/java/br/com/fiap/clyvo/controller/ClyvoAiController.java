package br.com.fiap.clyvo.controller;

import br.com.fiap.clyvo.dto.ia.ClyvoAiRequestDTO;
import br.com.fiap.clyvo.dto.ia.ClyvoAiResponseDTO;
import br.com.fiap.clyvo.service.ClyvoAiService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/ia")
public class ClyvoAiController {

    private final ClyvoAiService clyvoAiService;

    public ClyvoAiController(
            ClyvoAiService clyvoAiService
    ) {
        this.clyvoAiService = clyvoAiService;
    }

    @PostMapping("/score")
    public ResponseEntity<ClyvoAiResponseDTO> calcularScore(
            @RequestBody ClyvoAiRequestDTO request
    ) {

        ClyvoAiResponseDTO response =
                clyvoAiService.calcularScore(request);

        return ResponseEntity.ok(response);
    }
}