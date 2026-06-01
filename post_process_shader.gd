@tool
extends CompositorEffect
class_name PostProcessShader

const template_shader: String = """
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;
layout(rgba16f, set = 0, binding = 0) uniform image2D color_image;
layout(push_constant, std430) uniform Params {
	vec2 raster_size;
	vec2 reserved;
} params;

void main() {
	ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
	ivec2 size = ivec2(params.raster_size);
	imageStore(color_image, uv, vec4(0.0, 0.5, 0.0, 1.0));
}
"""

var rd: RenderingDevice
var shader: RID
var pipeline: RID


func _init() -> void:
	effect_callback_type = CompositorEffect.EFFECT_CALLBACK_TYPE_POST_TRANSPARENT
	rd = RenderingServer.get_rendering_device()

	var shader_source := RDShaderSource.new()
	shader_source.language = RenderingDevice.SHADER_LANGUAGE_GLSL
	shader_source.source_compute = template_shader

	var shader_spirv := rd.shader_compile_spirv_from_source(shader_source)
	shader = rd.shader_create_from_spirv(shader_spirv)
	pipeline = rd.compute_pipeline_create(shader)


func _render_callback(p_effect_callback_type, p_render_data) -> void:
	var render_scene_buffers: RenderSceneBuffersRD = p_render_data.get_render_scene_buffers()
	var size := render_scene_buffers.get_internal_size()
	var x_groups := ceili(float(size.x) / 8.0)
	var y_groups := ceili(float(size.y) / 8.0)

	var push_constant := PackedFloat32Array()
	push_constant.push_back(size.x)
	push_constant.push_back(size.y)
	push_constant.push_back(0.0)
	push_constant.push_back(0.0)

	var view_count := render_scene_buffers.get_view_count()
	for view in range(view_count):
		var input_image := render_scene_buffers.get_color_layer(view)
		var uniform := RDUniform.new()
		uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
		uniform.binding = 0
		uniform.add_id(input_image)

		var uniform_set := UniformSetCacheRD.get_cache(shader, 0, [uniform])

		rd.draw_command_begin_label("POST PROCESS PASS", Color.GREEN)
		var compute_list := rd.compute_list_begin()
		rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
		rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
		rd.compute_list_set_push_constant(
			compute_list,
			push_constant.to_byte_array(),
			push_constant.size() * 4
		)
		rd.compute_list_dispatch(compute_list, x_groups, y_groups, 1)
		rd.compute_list_end()
		rd.draw_command_end_label()
