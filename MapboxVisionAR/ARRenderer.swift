//
//  ARRenderer.swift
//  VisionSDK
//
//  Created by Denis Koronchik on 8/21/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import MetalKit
import MapboxVision

// design
let kArrowColor = float4(0.2745, 0.4117, 0.949, 0.99)
let kGridColor = float4(0.952, 0.0549, 0.3607, 0.95)

// world transforms
let kTurnOffsetAfterOriginM = Float(10)  // meters
let kArrowMaxLengthM        = Float(25)  // meters
let kMinArrowMidOffset      = Float(0.5) // meters
let kAnimResetArrowSpeed    = Float(10)  // meters / sec

struct DefaultVertexUniforms {
    var viewProjectionMatrix: float4x4
    var modelMatrix: float4x4
    var normalMatrix: float3x3
}

struct ArrowVertexUniforms {
    var viewProjectionMatrix: float4x4
    var modelMatrix: float4x4
    var normalMatrix: float3x3
    var p0: float3
    var p1: float3
    var p2: float3
    var p3: float3
}

struct FragmentUniforms {
    var cameraWorldPosition = float3(0, 0, 0)
    var ambientLightColor = float3(0, 0, 0)
    var specularColor = float3(1, 1, 1)
    var baseColor = float3(1, 1, 1)
    var opacity = Float(1)
    var specularPower = Float(1)
    var light = ARLight()
}

struct LaneFragmentUniforms {
    var baseColor = float4(1, 1, 1, 1)
};

/* Coordinate system:
 *      Y
 *      ^
 *      |
 *      0 -----> X
 *     /
 *    /
 *   Z
 */

class ARRenderer: NSObject, MTKViewDelegate {
    
    private let dataProvider: ARDataProvider
    private let device: MTLDevice
    private var textureCache: CVMetalTextureCache?
    private let commandQueue: MTLCommandQueue
    private let vertexDescriptor: MDLVertexDescriptor = ARRenderer.makeVertexDescriptor()
    private let renderPipelineDefault: MTLRenderPipelineState
    private let renderPipelineArrow: MTLRenderPipelineState
    private let renderPipelineBackground: MTLRenderPipelineState
    private let samplerStateDefault: MTLSamplerState
    private let depthStencilStateDefault: MTLDepthStencilState
    
    private var viewProjectionMatrix = matrix_identity_float4x4
    private var defaultLight = ARLight()
    
    private let scene = ARScene()
    private var time = Float(0)
    private var dt = Float(0)
    
    private let gridNode = ARNode(name: "Grid")
    private let arrowNode = ARNode(name: "Arrow")
    private let bundle = Bundle(for: ARRenderer.self)
    
    private var arrowStartPoint = float3(0, 0, 0)
    private var arrowEndPoint = float3(0, 0, 0)
    private var arrowMidPoint = float3(0, 0, 0)
    
    private var arrowControlPoints: [float3]
    
    enum ARRendererError: LocalizedError {
        case cantCreateCommandQueue
        case cantCreateTextureCache
        case cantFindMeshFile(String)
        case meshFileIsEmpty(String)
        case cantFindFunctions
    }
    
    init(device: MTLDevice, dataProvider: ARDataProvider, colorPixelFormat: MTLPixelFormat, depthStencilPixelFormat: MTLPixelFormat) throws {
        self.device = device
        self.dataProvider = dataProvider
        self.arrowControlPoints = []
        
        guard CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &textureCache) == kCVReturnSuccess else {
            throw ARRendererError.cantCreateTextureCache
        }
        
        guard let commandQueue = device.makeCommandQueue() else { throw ARRendererError.cantCreateCommandQueue }
        self.commandQueue = commandQueue
        self.commandQueue.label = "com.mapbox.ARRenderer"
        
        let library = try device.makeDefaultLibrary(bundle: bundle)
        
        guard
        let defaultVertexFunction = library.makeFunction(name: "default_vertex_main"),
        let arrowVertexFunction = library.makeFunction(name: "arrow_vertex_main"),
        let backgroundVertexFunction = library.makeFunction(name: "map_texture"),
        let defaultFragmentFunction = library.makeFunction(name: "default_fragment_main"),
        let arrowFragmentFunction = library.makeFunction(name: "lane_fragment_main"),
        let backgroundFragmentFunction = library.makeFunction(name: "display_texture")
        else { throw ARRendererError.cantFindFunctions }
        
        renderPipelineDefault = try ARRenderer.makeRenderPipeline(device: device,
                                                                  vertexDescriptor: vertexDescriptor,
                                                                  vertexFunction: defaultVertexFunction,
                                                                  fragmentFunction: defaultFragmentFunction,
                                                                  colorPixelFormat: colorPixelFormat,
                                                                  depthStencilPixelFormat: depthStencilPixelFormat)
        
        renderPipelineArrow = try ARRenderer.makeRenderPipeline(device: device,
                                                                vertexDescriptor: vertexDescriptor,
                                                                vertexFunction: arrowVertexFunction,
                                                                fragmentFunction: arrowFragmentFunction,
                                                                colorPixelFormat: colorPixelFormat,
                                                                depthStencilPixelFormat: depthStencilPixelFormat)
        
        
        renderPipelineBackground = try ARRenderer.makeRenderPipeline(device: device,
                                                                     vertexDescriptor: nil,
                                                                     vertexFunction: backgroundVertexFunction,
                                                                     fragmentFunction: backgroundFragmentFunction,
                                                                     colorPixelFormat: colorPixelFormat,
                                                                     depthStencilPixelFormat: depthStencilPixelFormat)
        
        samplerStateDefault = ARRenderer.makeDefaultSamplerState(device: device)
        depthStencilStateDefault = ARRenderer.makeDefaultDepthStencilState(device: device)
            
        super.init()
    }
    
    private func loadMesh(name: String) throws -> MTKMesh {
        let bufferAllocator = MTKMeshBufferAllocator(device: device)
        guard let meshURL = bundle.url(forResource: name, withExtension: "obj") else {
            throw ARRendererError.cantFindMeshFile(name)
        }
        let meshAsset = MDLAsset(url: meshURL, vertexDescriptor: vertexDescriptor, bufferAllocator: bufferAllocator)
        let meshes = try MTKMesh.newMeshes(asset: meshAsset, device: device).metalKitMeshes
        guard let mesh = meshes.first else { throw ARRendererError.meshFileIsEmpty(name) }
        return mesh
    }
    
    func initScene() {
        // load resources
//        let gridMesh = loadMesh(name: "grid")
//        let gridEntity = AREntity(mesh: gridMesh)
//        gridEntity.material.diffuseColor = kGridColor
//        gridEntity.material.specularPower = 500
//        gridNode.entity = gridEntity
//        scene.rootNode.add(child: gridNode)

        do {
            let arrowMesh = try loadMesh(name: "lane")
            let arrowEntity = AREntity(mesh: arrowMesh)
            arrowEntity.material.diffuseColor = kArrowColor
            arrowEntity.material.specularPower = 100
            arrowEntity.material.specularColor = float3(1, 1, 1) //kArrowColor.xyz
            arrowEntity.material.ambientLightColor = kArrowColor.xyz //float3(0.5, 0.5, 0.5)
            arrowEntity.renderPipeline = renderPipelineArrow
            
            arrowNode.entity = arrowEntity
            arrowNode.position = float3(0, 0, 0)
            scene.rootNode.add(child: arrowNode)
            
            // configure default light
            defaultLight = ARLight(color: float3(1, 1, 1), position: float3(0, 7, 0))
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }
    
    static func makeVertexDescriptor() -> MDLVertexDescriptor {
        
        let vertexDescriptor = MDLVertexDescriptor()
        vertexDescriptor.attributes[0] = MDLVertexAttribute(
            name: MDLVertexAttributePosition,
            format: .float3,
            offset: 0,
            bufferIndex: 0)
        vertexDescriptor.attributes[1] = MDLVertexAttribute(
            name: MDLVertexAttributeNormal,
            format: .float3,
            offset: MemoryLayout<Float>.size * 3,
            bufferIndex: 0)
        vertexDescriptor.attributes[2] = MDLVertexAttribute(
            name: MDLVertexAttributeTextureCoordinate,
            format: .float2,
            offset: MemoryLayout<Float>.size * 6,
            bufferIndex: 0)
        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: MemoryLayout<Float>.size * 8)
        return vertexDescriptor
    }
    
    static func makeRenderPipeline(device: MTLDevice,
                                   vertexDescriptor: MDLVertexDescriptor?,
                                   vertexFunction: MTLFunction,
                                   fragmentFunction: MTLFunction,
                                   colorPixelFormat: MTLPixelFormat,
                                   depthStencilPixelFormat: MTLPixelFormat) throws -> MTLRenderPipelineState {
        
        let pipeline = MTLRenderPipelineDescriptor()
        pipeline.vertexFunction = vertexFunction
        pipeline.fragmentFunction = fragmentFunction
        
        pipeline.colorAttachments[0].pixelFormat = colorPixelFormat
        pipeline.colorAttachments[0].isBlendingEnabled = true
        pipeline.colorAttachments[0].rgbBlendOperation = MTLBlendOperation.add
        pipeline.colorAttachments[0].alphaBlendOperation = MTLBlendOperation.add
        pipeline.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactor.sourceAlpha
        pipeline.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactor.sourceAlpha
        pipeline.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactor.oneMinusSourceAlpha
        pipeline.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactor.oneMinusSourceAlpha
        pipeline.depthAttachmentPixelFormat = depthStencilPixelFormat
        
        if let vertexDescriptor = vertexDescriptor {
            let mtlVertexDescriptor = MTKMetalVertexDescriptorFromModelIO(vertexDescriptor)
            pipeline.vertexDescriptor = mtlVertexDescriptor
        }
        
        return try device.makeRenderPipelineState(descriptor: pipeline)
    }
    
    static func makeDefaultSamplerState(device: MTLDevice) -> MTLSamplerState {
        
        let sampler = MTLSamplerDescriptor()
        
        sampler.minFilter = .linear
        sampler.mipFilter = .linear
        sampler.magFilter = .linear
        
        sampler.normalizedCoordinates = true
        return device.makeSamplerState(descriptor: sampler)!
    }
    
    static func makeDefaultDepthStencilState(device: MTLDevice) -> MTLDepthStencilState {
        
        let depthStencil = MTLDepthStencilDescriptor()
        
        depthStencil.isDepthWriteEnabled = true
        depthStencil.depthCompareFunction = .less
        
        return device.makeDepthStencilState(descriptor: depthStencil)!
    }
    
    func update(_ view: MTKView) {
        dt = 1 / Float(view.preferredFramesPerSecond)
        time += dt
        
        let camParams = dataProvider.getCameraParams();
        scene.camera.aspectRatio = camParams.aspectRatio;
        scene.camera.fovRadians = camParams.verticalFOV;
        scene.camera.rotation = simd_quatf.byAxis(camParams.roll - Float.pi / 2, -camParams.pitch, 0)
        
        scene.camera.position = float3(0, camParams.height, 0);
        
        updateLane()
    }
    
    func drawScene(commandEncoder: MTLRenderCommandEncoder) {

        let viewMatrix = makeViewMatrix(trans: scene.camera.position, rot: scene.camera.rotation)
        viewProjectionMatrix = scene.camera.projectionMatrix() * viewMatrix
        
        // TODO: reorder for less pixeloverdraw
        scene.rootNode.childs.forEach { (node) in
            if let entity = node.entity, let mesh = entity.mesh {
                
                if let pipeline = entity.renderPipeline {
                    commandEncoder.setRenderPipelineState(pipeline)
                } else {
                    commandEncoder.setRenderPipelineState(renderPipelineDefault)
                }

                let modelMatrix = node.worldTransform()
                let material = entity.material
                // TODO: make it in common case
                if node === arrowNode {
                    var vertexUniforms = ArrowVertexUniforms(
                        viewProjectionMatrix: viewProjectionMatrix,
                        modelMatrix: modelMatrix,
                        normalMatrix: normalMatrix(mat: modelMatrix),
                        p0: arrowControlPoints[0],
                        p1: arrowControlPoints[1],
                        p2: arrowControlPoints[2],
                        p3: arrowControlPoints[3])
                    commandEncoder.setVertexBytes(&vertexUniforms, length: MemoryLayout<ArrowVertexUniforms>.size, index: 1)
                    
//                    var fragmentUniforms = LaneFragmentUniforms(baseColor: material.diffuseColor)
//
//                    commandEncoder.setFragmentBytes(&fragmentUniforms, length: MemoryLayout<LaneFragmentUniforms>.size, index: 0)
                } else {
                    var vertexUniforms = DefaultVertexUniforms(
                        viewProjectionMatrix: viewProjectionMatrix,
                        modelMatrix: modelMatrix,
                        normalMatrix: normalMatrix(mat: modelMatrix))
                    commandEncoder.setVertexBytes(&vertexUniforms, length: MemoryLayout<DefaultVertexUniforms>.size, index: 1)
                    
                    
                }
                
                let light = material.light ?? defaultLight
                var fragmentUniforms = FragmentUniforms(cameraWorldPosition: scene.camera.position,
                                                        ambientLightColor: material.ambientLightColor,
                                                        specularColor: material.specularColor,
                                                        baseColor: material.diffuseColor.xyz,
                                                        opacity: material.diffuseColor.w,
                                                        specularPower: material.specularPower,
                                                        light: light)
                
                commandEncoder.setFragmentBytes(&fragmentUniforms, length: MemoryLayout<FragmentUniforms>.size, index: 0)

                commandEncoder.setFrontFacing(material.frontFaceMode)

                // commandEncoder.setFragmentTexture(baseColorTexture, index: 0)

                let vertexBuffer = mesh.vertexBuffers.first!
                commandEncoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: 0)

                for submesh in mesh.submeshes {
                    let indexBuffer = submesh.indexBuffer
                    commandEncoder.drawIndexedPrimitives(type: submesh.primitiveType,
                                                         indexCount: submesh.indexCount,
                                                         indexType: submesh.indexType,
                                                         indexBuffer: indexBuffer.buffer,
                                                         indexBufferOffset: indexBuffer.offset)
                }
            }
        }
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // TODO: update camera
    }
    
    func draw(in view: MTKView) {
        update(view)
        
        // render
        guard
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let renderPass = view.currentRenderPassDescriptor,
            let drawable = view.currentDrawable
        else { return }
        
        renderPass.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0)
        
        guard let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPass)
        else { return }
        
        
        
        if let frame = dataProvider.getCurrentFrame(), let texture = makeTexture(from: frame) {
            commandEncoder.setRenderPipelineState(renderPipelineBackground)
            commandEncoder.setFragmentTexture(texture, index: 0)
            commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 1)
        }
        
        commandEncoder.setFrontFacing(.counterClockwise)
        commandEncoder.setCullMode(.back)
        commandEncoder.setDepthStencilState(depthStencilStateDefault)
        commandEncoder.setRenderPipelineState(renderPipelineDefault)
        commandEncoder.setFragmentSamplerState(samplerStateDefault, index: 0)
        
        drawScene(commandEncoder: commandEncoder)
        
        commandEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    private func makeTexture(from buffer: CVPixelBuffer) -> MTLTexture? {
        var imageTexture: CVMetalTexture?
        guard let textureCache = textureCache,
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache, buffer, nil, .bgra8Unorm, CVPixelBufferGetWidth(buffer), CVPixelBufferGetHeight(buffer), 0, &imageTexture) == kCVReturnSuccess
        else { return nil }
        return CVMetalTextureGetTexture(imageTexture!)
    }
    
    private func updateLane() {
        let data = dataProvider.getARRouteData()
        let (p0, p1, p2, p3) = data.points
        
        arrowControlPoints = [
            float3(Float(p0.x), Float(p0.z), Float(-p0.y)),
            float3(Float(p1.x), Float(p1.z), Float(-p1.y)),
            float3(Float(p2.x), Float(p2.z), Float(-p2.y)),
            float3(Float(p3.x), Float(p3.z), Float(-p3.y))
        ]
    }
}
