package br.com.fiap.clyvo;

import br.com.fiap.clyvo.config.RestClientConfig;
import br.com.fiap.clyvo.exception.TratadorDeErros;
import br.com.fiap.clyvo.service.ClyvoAiService;
import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.web.client.RestClientException;
import org.springframework.web.server.ResponseStatusException;

import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.atomic.AtomicReference;

import static org.junit.jupiter.api.Assertions.*;

class ClyvoAiServiceTest {
    @Test
    void enviaImagemComTamanhoETipoExplicitos() throws Exception {
        var server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        var length = new AtomicReference<String>();
        var body = new AtomicReference<String>();
        server.createContext("/api/v2/pets/analyze-registration-photo", exchange -> {
            length.set(exchange.getRequestHeaders().getFirst("Content-Length"));
            body.set(new String(exchange.getRequestBody().readAllBytes(), StandardCharsets.UTF_8));
            byte[] response = "{\"origem\":\"teste\",\"requer_confirmacao\":true}".getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().set("Content-Type", "application/json");
            exchange.sendResponseHeaders(200, response.length);
            exchange.getResponseBody().write(response);
            exchange.close();
        });
        server.start();
        try {
            var service = service(server, 1000);
            var result = service.analisarFotoCadastro(image());
            assertEquals("teste", result.origem());
            assertNotNull(length.get());
            assertTrue(body.get().contains("name=\"imagem\""));
            assertTrue(body.get().contains("Content-Type: image/jpeg"));
            assertTrue(body.get().contains("image-content"));
        } finally {
            server.stop(0);
        }
    }

    @Test
    void interrompeEsperaQuandoIaNaoResponde() throws Exception {
        var server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/api/v2/pets/analyze-registration-photo", exchange -> {
            exchange.getRequestBody().readAllBytes();
            try { Thread.sleep(600); }
            catch (InterruptedException ex) { Thread.currentThread().interrupt(); }
            finally { exchange.close(); }
        });
        server.start();
        try {
            var service = service(server, 100);
            var error = assertThrows(RestClientException.class,
                    () -> service.analisarFotoCadastro(image()));
            assertEquals(504, new TratadorDeErros().tratarRespostaIa(error).getStatusCode().value());
        } finally {
            server.stop(0);
        }
    }

    @Test
    void rejeitaArquivoVazioAntesDeChamarIa() {
        var service = new ClyvoAiService(new RestClientConfig().restClientBuilder(100, 100), "http://127.0.0.1:1");
        var error = assertThrows(ResponseStatusException.class, () -> service.analisarFotoCadastro(
                new MockMultipartFile("imagem", "pet.jpg", "image/jpeg", new byte[0])));
        assertEquals(400, error.getStatusCode().value());
    }

    private ClyvoAiService service(HttpServer server, int timeout) {
        return new ClyvoAiService(new RestClientConfig().restClientBuilder(1000, timeout),
                "http://127.0.0.1:" + server.getAddress().getPort());
    }

    private MockMultipartFile image() {
        return new MockMultipartFile("imagem", "pet.jpg", "image/jpeg",
                "image-content".getBytes(StandardCharsets.UTF_8));
    }
}
