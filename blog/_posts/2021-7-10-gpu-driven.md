---
date: 2021-7-10
tags:
  - graphics
  - game-engine
author: HEBO496
location: SuZhou-China
---

# GPU-Driven

在传统的渲染引擎中，CPU处理了许多逻辑，例如剔除，资源绑定，绘制排序，合批等，而这导致许多时候性能瓶颈往往出现在CPU与总线上。为了避免这一问题，现代图形API引入了ComputeShader，IndirectDraw，BindlessTexture等技术，设法让GPU参与更多的逻辑，降低CPU提交数据与管线状态改变的频率。下面将简单介绍几种重要的GPU-Driven技术及其应用。

## Compute In Render Pipeline

在ComputeShader之前，我们已经可以使用CUDA,OpenCL等方式在GPGPU设备上进行General-Purpose并行计算，在渲染引擎中使用这些技术也是可行的，但在存在一些问题，一个是他们的编程模式差别导致技术人员要学习新的模式，这不适合图形程序员快速开展工作，另外由于他们与渲染管线是各自独立的软件接口，所以在同步与硬件资源分配调度上很难做优化，甚至有些资源我们需要为他们各自提交一份数据，这显然是浪费的，ComputeShader是在渲染管线上的一个相对独立的Stage，他提供着色器的语法，与渲染管线资源的访问与同步。MeshShader则更进一步，在ComputeShader的基础上增加了对顶点与图元的控制，直接将传统的VertexShader给取代了，并提供了更大的自由度。

### Meshlets/MeshClusters

传统模式有个很大的限制是我们一次绘制命令只能绘制一个模型或同种模型的多个实例，而在随着场景越来越复杂，cpu的命令也随之增长。传统的优化做法是进行合批操作，尽可能的少改变管线状态，或在一次绘制中绘制多个实例或模型。但我们是否有办法在一次绘制中绘制多种模型的多个实例。Merge-Instaning的想法作为一把关键钥匙，开启了渲染管线新的时代。它的想法是将模型切分为大小一致的Cluster/Meshlet，这样模型就可以被归一化处理了，所有模型实例就被划分为若干Meshlet的实例。以Meshlet包含Vertex的个数作为Vertex的个数，Meshlet实例个数作为实例个数，通过InstancedDraw即可驱动绘制。这时我们不能简单的通过VertexBuffer与IndexBuffer传递绘制数据，而要自己进行VertexFetch。维护一张存放每种Mesh的实例个数与Meshlet个数的前缀和数组，通过InstanceId对其进行二分访问，得到LowerBound。此时返回的下标既是MeshId，通过前缀差获取当前Mesh的实例个数，Meshlet个数。通过这些数据可进一步得到MeshInstaceId，MeshMeshletId，VertexId。这样我们就可从对应Buffer中索引到相应数据。

### GPU IA(Input Assembler)

### GPU Culling

GPU-Driven一个最常见的应用就是GPU剔除，顾名思义就是在使用GPU并行地进行剔除计算。首先计算出场景中所有对象的包围体积，将这些数据与各个相机的平截头提交到Shader中，在Shader中进行剔除计算，包括对每份包围体积在每个平截头进行相交判断，基于深度图与Hi-Z图进行遮档剔除，基于包围锥进行背面剔除，由此构建IndirectDrawBuffer。这样Cpu就只有一个DrawCall，且不用处理绘制命令。

### Virtual Texture And Bindless Texture

### V-Buffer

