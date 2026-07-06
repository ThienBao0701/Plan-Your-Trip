package com.example.planyourtrip.config;
import org.springframework.context.annotation.Configuration; import org.springframework.web.method.support.HandlerMethodArgumentResolver; import org.springframework.web.servlet.config.annotation.WebMvcConfigurer; import java.util.List;
@Configuration public class WebConfig implements WebMvcConfigurer { private final AuthUserResolver resolver; public WebConfig(AuthUserResolver resolver){this.resolver=resolver;} public void addArgumentResolvers(List<HandlerMethodArgumentResolver> resolvers){resolvers.add(resolver);} }
