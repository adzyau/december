import express from "express";
import { v4 as uuidv4 } from "uuid";
import * as dockerService from "../services/docker";
import * as exportService from "../services/export";
import * as fileService from "../services/file";
import * as packageService from "../services/package";

const router = express.Router();

router.get("/", async (req, res) => {
  try {
    const containers = await dockerService.listContainers();

    res.json({
      success: true,
      containers: containers.map(container => ({
        id: container.id,
        name: container.name,
        status: container.status,
        port: container.port,
        url: container.port ? `http://localhost:${container.port}` : null,
        type: "Next.js App"
      })),
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
});

router.post("/create", async (req, res) => {
  const containerId = uuidv4();

  try {
    // Create default Next.js app files
    const defaultFiles = {
      "package.json": JSON.stringify({
        name: "my-nextjs-app",
        version: "0.1.0",
        private: true,
        scripts: {
          dev: "next dev",
          build: "next build",
          start: "next start",
          lint: "next lint",
        },
        dependencies: {
          next: "13.4.19",
          react: "^18.2.0",
          "react-dom": "^18.2.0",
        },
        devDependencies: {
          "@types/node": "^20",
          "@types/react": "^18",
          "@types/react-dom": "^18",
          typescript: "^5",
        },
      }, null, 2),
      "pages/index.tsx": `export default function Home() {
  return (
    <div>
      <h1>Welcome to December!</h1>
      <p>Your Next.js app is running.</p>
    </div>
  );
}`
    };

    const imageName = await dockerService.buildImage(containerId);
    const result = await dockerService.runContainer(
      imageName,
      containerId,
      defaultFiles
    );

    res.json({
      success: true,
      containerId: result.containerId,
      container: {
        id: containerId,
        containerId: result.containerId,
        status: "running",
        port: result.port,
        url: result.url,
        createdAt: new Date().toISOString(),
        type: "Next.js App",
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
});

router.post("/:containerId/start", async (req, res) => {
  const { containerId } = req.params;

  try {
    // For CLI-based implementation, we'll return the existing container info
    const containers = await dockerService.listContainers();
    const container = containers.find(c => c.id === containerId || c.name.includes(containerId));
    
    if (!container) {
      throw new Error("Container not found");
    }

    res.json({
      success: true,
      containerId,
      port: container.port,
      url: container.port ? `http://localhost:${container.port}` : null,
      status: container.status,
      message: "Container info retrieved successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
});

router.post("/:containerId/stop", async (req, res) => {
  const { containerId } = req.params;

  try {
    await dockerService.stopContainer(containerId);

    res.json({
      success: true,
      containerId,
      status: "stopped",
      message: "Container stopped successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
});

router.delete("/:containerId", async (req, res) => {
  const { containerId } = req.params;

  try {
    await dockerService.stopContainer(containerId);

    res.json({
      success: true,
      containerId,
      message: "Container deleted successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
});

router.get("/:containerId/files", async (req, res) => {
  const { containerId } = req.params;
  const { path: containerPath = "/app/src" } = req.query;

  try {
    // For CLI implementation, we'll use a simple file listing
    const files = await dockerService.execInContainer(
      containerId,
      `find ${containerPath} -type f -name "*.tsx" -o -name "*.ts" -o -name "*.js" -o -name "*.jsx" -o -name "*.json" | head -20`
    );

    const fileList = files.split('\n')
      .filter(f => f.trim())
      .map(f => ({
        name: f.split('/').pop(),
        path: f,
        type: 'file',
        size: 0
      }));

    res.json({
      success: true,
      path: containerPath,
      files: fileList,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
});

router.get("/:containerId/file-tree", async (req, res) => {
  const { containerId } = req.params;

  try {
    // Simple file tree using CLI
    const output = await dockerService.execInContainer(
      containerId,
      `find /app/src -type f | head -50`
    );

    const files = output.split('\n').filter(f => f.trim());
    const fileTree = {
      name: "src",
      type: "directory",
      children: files.map(f => ({
        name: f.split('/').pop(),
        path: f,
        type: "file"
      }))
    };

    res.json({
      success: true,
      fileTree,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
});

router.get("/:containerId/file-content-tree", async (req, res) => {
  const { containerId } = req.params;

  try {
    // Get file tree with content
    const output = await dockerService.execInContainer(
      containerId,
      `find /app/src -name "*.tsx" -o -name "*.ts" -o -name "*.js" -o -name "*.jsx" | head -10`
    );

    const files = output.split('\n').filter(f => f.trim());
    const fileContentTree = [];

    for (const file of files) {
      try {
        const content = await dockerService.getContainerFiles(containerId, file.replace('/app/src/', ''));
        fileContentTree.push({
          path: file,
          name: file.split('/').pop(),
          content,
          type: "file"
        });
      } catch (err) {
        console.warn(`Could not read file ${file}:`, err);
      }
    }

    res.json({
      success: true,
      fileContentTree,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
});

//@ts-ignore
router.get("/:containerId/file", async (req, res) => {
  const { containerId } = req.params;
  const { path: filePath } = req.query;

  if (!filePath) {
    return res.status(400).json({
      success: false,
      error: "File path is required",
    });
  }

  try {
    const content = await dockerService.getContainerFiles(
      containerId,
      filePath as string
    );

    res.json({
      success: true,
      path: filePath,
      content,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
});

//@ts-ignore
router.put("/:containerId/file", async (req, res) => {
  const { containerId } = req.params;
  const { path: filePath, content } = req.body;

  if (!filePath || content === undefined) {
    return res.status(400).json({
      success: false,
      error: "File path and content are required",
    });
  }

  try {
    await dockerService.updateContainerFiles(
      containerId,
      { [filePath]: content }
    );

    res.json({
      success: true,
      path: filePath,
      message: "File updated successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
});

//@ts-ignore
router.put("/:containerId/files", async (req, res) => {
  const { containerId } = req.params;
  const { files } = req.body;

  if (!files || typeof files !== "object") {
    return res.status(400).json({
      success: false,
      error: "Files object is required",
    });
  }

  try {
    await dockerService.updateContainerFiles(containerId, files);

    res.json({
      success: true,
      message: "Files updated successfully",
      updatedFiles: Object.keys(files),
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
});

router.get("/:containerId/logs", async (req, res) => {
  const { containerId } = req.params;

  try {
    const logs = await dockerService.getContainerLogs(containerId);

    res.json({
      success: true,
      logs,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
});

router.get("/:containerId/package", async (req, res) => {
  const { containerId } = req.params;

  try {
    const packageJson = await dockerService.getContainerFiles(
      containerId,
      "package.json"
    );

    res.json({
      success: true,
      package: JSON.parse(packageJson),
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
});

router.put("/:containerId/package", async (req, res) => {
  const { containerId } = req.params;
  const { package: packageData } = req.body;

  if (!packageData) {
    return res.status(400).json({
      success: false,
      error: "Package data is required",
    });
  }

  try {
    await dockerService.updateContainerFiles(
      containerId,
      { "package.json": JSON.stringify(packageData, null, 2) }
    );

    res.json({
      success: true,
      message: "Package.json updated successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
});

router.post("/:containerId/export", async (req, res) => {
  const { containerId } = req.params;

  try {
    const zipBuffer = await exportService.exportContainerFiles(containerId);

    res.setHeader("Content-Type", "application/zip");
    res.setHeader(
      "Content-Disposition",
      `attachment; filename=container-${containerId}.zip`
    );

    res.send(zipBuffer);
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
});

export default router;
