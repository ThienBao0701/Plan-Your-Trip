package com.example.planyourtrip.security;
import com.fasterxml.jackson.databind.ObjectMapper; import org.springframework.beans.factory.annotation.Value; import org.springframework.stereotype.Service; import javax.crypto.Mac; import javax.crypto.spec.SecretKeySpec; import java.nio.charset.StandardCharsets; import java.time.Instant; import java.util.*;
/**
 * HS256 JWT with {@code sub} (user id), {@code email}, {@code exp} and — since Phase A — {@code ver}, the
 * account's {@code tokenVersion} when the token was issued. A token without {@code ver} (issued before
 * Phase A) reads as version 0. The version is compared against the account on every request by
 * {@link JwtAuthenticationFilter}; nothing else about the account is trusted from the token.
 */
@Service
public class JwtService { private final String secret; private final long expirationMs; private final ObjectMapper mapper=new ObjectMapper(); public JwtService(@Value("${app.jwt.secret}") String secret,@Value("${app.jwt.expiration-ms}") long expirationMs){this.secret=secret;this.expirationMs=expirationMs;}
 /** The verified claims of a token: whose it is and which session version it was issued for. */
 public record TokenClaims(Long userId, int tokenVersion) {}
 public String createToken(Long userId, String email, int tokenVersion){ try{ Map<String,Object> header=Map.of("alg","HS256","typ","JWT"); Map<String,Object> payload=new LinkedHashMap<>(); payload.put("sub", String.valueOf(userId)); payload.put("email", email); payload.put("ver", tokenVersion); payload.put("exp", Instant.now().plusMillis(expirationMs).getEpochSecond()); String h=b64(mapper.writeValueAsBytes(header)); String p=b64(mapper.writeValueAsBytes(payload)); return h+"."+p+"."+sign(h+"."+p); }catch(Exception e){ throw new IllegalStateException("Could not create token"); }}
 /** The claims of a correctly signed, unexpired token, or empty. A {@code ver} that is present but not an integer is invalid. */
 public Optional<TokenClaims> parse(String token){ try{ String[] parts=token.split("\\."); if(parts.length!=3 || !sign(parts[0]+"."+parts[1]).equals(parts[2])) return Optional.empty(); Map<?,?> body=mapper.readValue(Base64.getUrlDecoder().decode(parts[1]), Map.class); Number exp=(Number)body.get("exp"); if(exp.longValue()<Instant.now().getEpochSecond()) return Optional.empty(); Object ver=body.get("ver"); int version; if(ver==null) version=0; else if(ver instanceof Integer i) version=i; else return Optional.empty(); return Optional.of(new TokenClaims(Long.valueOf((String)body.get("sub")), version)); }catch(Exception e){ return Optional.empty(); }}
 private String sign(String data) throws Exception { Mac mac=Mac.getInstance("HmacSHA256"); mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8),"HmacSHA256")); return b64(mac.doFinal(data.getBytes(StandardCharsets.UTF_8))); } private String b64(byte[] data){ return Base64.getUrlEncoder().withoutPadding().encodeToString(data); }}
