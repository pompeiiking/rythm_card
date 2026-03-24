shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(0.0, 1.0, 1.0, 0.6);
uniform float glow_intensity : hint_range(0.0, 2.0) = 0.8;
uniform float glow_radius : hint_range(1.0, 3.0) = 1.3;
uniform float glow_falloff : hint_range(0.1, 2.0) = 0.5;

void fragment() {
    vec2 uv = UV;
    vec2 center = vec2(0.5, 0.5);
    
    // 计算当前像素到中心的距离（考虑非正方形情况）
    vec2 dist_vec = uv - center;
    float dist = length(dist_vec * vec2(TEXTURE_PIXEL_SIZE.y / TEXTURE_PIXEL_SIZE.x, 1.0));
    
    // 原始纹理颜色
    vec4 tex_color = texture(TEXTURE, uv);
    
    // 计算光晕强度（基于距离衰减）
    float normalized_dist = dist / 0.5; // 归一化到 0-1
    float glow_factor = 1.0 - clamp(normalized_dist / glow_radius, 0.0, 1.0);
    glow_factor = pow(glow_factor, glow_falloff);
    
    // 边缘发光效果
    float edge_glow = smoothstep(0.4, 0.5, dist) * glow_intensity;
    
    // 组合光晕
    float total_glow = glow_factor * glow_intensity + edge_glow;
    
    // 最终颜色：原始纹理 + 光晕叠加
    vec4 final_color = tex_color;
    if (total_glow > 0.0) {
        final_color.rgb = mix(final_color.rgb, glow_color.rgb, total_glow * glow_color.a);
        final_color.a = max(final_color.a, total_glow * 0.8);
    }
    
    COLOR = final_color;
}