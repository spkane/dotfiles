import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Text, truncateToWidth } from "@earendil-works/pi-tui";
import { Type } from "typebox";
import { spawn } from "node:child_process";
import { createServer, type IncomingMessage, type ServerResponse } from "node:http";
import { promises as fs } from "node:fs";
import { existsSync } from "node:fs";
import os from "node:os";
import path from "node:path";
import { randomUUID } from "node:crypto";

const ContextBlockSchema = Type.Object({
	type: Type.Optional(
		Type.Union([
			Type.Literal("text"),
			Type.Literal("markdown"),
			Type.Literal("code"),
			Type.Literal("image"),
			Type.Literal("diagram"),
		]),
		{ description: "Context block type. Defaults to markdown when content is provided." },
	),
	title: Type.Optional(Type.String({ description: "Optional heading for this context block" })),
	content: Type.Optional(Type.String({ description: "Text, markdown, code, or diagram source to show" })),
	src: Type.Optional(
		Type.String({
			description:
				"Image/diagram URL, data URI, or local file path. Relative paths are resolved from the current pi working directory.",
		}),
	),
	alt: Type.Optional(Type.String({ description: "Alt text for images/diagrams" })),
	caption: Type.Optional(Type.String({ description: "Caption shown below images/diagrams" })),
	language: Type.Optional(Type.String({ description: "Language for code or diagram source, e.g. typescript, mermaid" })),
});

const OptionSchema = Type.Object({
	value: Type.Optional(Type.String({ description: "Stable value returned when selected. Defaults to label." })),
	label: Type.String({ description: "Display label for this option" }),
	description: Type.Optional(Type.String({ description: "Optional explanatory text below the option" })),
});

const QuestionSchema = Type.Object({
	id: Type.Optional(Type.String({ description: "Stable machine-readable id. Defaults to a generated id." })),
	label: Type.String({ description: "Question label shown to the human" }),
	help: Type.Optional(Type.String({ description: "Additional guidance shown below the label" })),
	type: Type.Optional(
		Type.Union([
			Type.Literal("radio"),
			Type.Literal("checkbox"),
			Type.Literal("confirm"),
			Type.Literal("text"),
			Type.Literal("textarea"),
		]),
		{ description: "Question input type. Defaults to radio when options exist, otherwise textarea." },
	),
	options: Type.Optional(Type.Array(OptionSchema, { description: "Options for radio/checkbox questions" })),
	required: Type.Optional(Type.Boolean({ description: "Whether the browser should require an answer when possible" })),
});

const SectionSchema = Type.Object({
	id: Type.Optional(Type.String({ description: "Stable machine-readable id. Defaults to a generated id." })),
	title: Type.String({ description: "Section header" }),
	summary: Type.Optional(Type.String({ description: "Short section summary shown before the toggle" })),
	initiallyOpen: Type.Optional(Type.Boolean({ description: "Whether the section context starts expanded. Default: true." })),
	context: Type.Optional(Type.Array(ContextBlockSchema, { description: "Relevant context blocks for this section" })),
	questions: Type.Array(QuestionSchema, { description: "Questions/forms in this section" }),
});

const AskHumanHtmlParams = Type.Object({
	title: Type.String({ description: "Page title and main heading" }),
	intro: Type.Optional(Type.String({ description: "Short introduction explaining why input is needed" })),
	sections: Type.Array(SectionSchema, { description: "Clear sections containing context and questions" }),
	submitLabel: Type.Optional(Type.String({ description: "Submit button text. Default: Submit responses" })),
	timeoutSeconds: Type.Optional(Type.Number({ description: "How long to wait for a browser response. Default: 3600." })),
	autoOpen: Type.Optional(Type.Boolean({ description: "Open the generated page in the local browser. Default: true." })),
});

type ContextBlock = {
	type?: "text" | "markdown" | "code" | "image" | "diagram";
	title?: string;
	content?: string;
	src?: string;
	alt?: string;
	caption?: string;
	language?: string;
};

type Option = { value?: string; label: string; description?: string };
type Question = {
	id?: string;
	label: string;
	help?: string;
	type?: "radio" | "checkbox" | "confirm" | "text" | "textarea";
	options?: Option[];
	required?: boolean;
};
type Section = {
	id?: string;
	title: string;
	summary?: string;
	initiallyOpen?: boolean;
	context?: ContextBlock[];
	questions: Question[];
};
type AskHumanHtmlInput = {
	title: string;
	intro?: string;
	sections: Section[];
	submitLabel?: string;
	timeoutSeconds?: number;
	autoOpen?: boolean;
};

type PreparedQuestion = Question & {
	id: string;
	formName: string;
	type: "radio" | "checkbox" | "confirm" | "text" | "textarea";
	options: Option[];
};

type PreparedSection = Omit<Section, "id" | "questions"> & {
	id: string;
	questions: PreparedQuestion[];
};

type PreparedForm = Omit<AskHumanHtmlInput, "sections"> & {
	sections: PreparedSection[];
};

type Asset = { id: string; absolutePath: string; mimeType: string };

type HumanHtmlResult = {
	title: string;
	url: string;
	pagePath: string;
	responsePath: string;
	submittedAt: string;
	responses: unknown;
};

function slug(input: string): string {
	const value = input
		.toLowerCase()
		.replace(/[^a-z0-9]+/g, "-")
		.replace(/^-+|-+$/g, "")
		.slice(0, 80);
	return value || "human-input";
}

function uniqueId(base: string, used: Set<string>): string {
	let candidate = slug(base);
	let i = 2;
	while (used.has(candidate)) {
		candidate = `${slug(base)}-${i}`;
		i++;
	}
	used.add(candidate);
	return candidate;
}

function escapeHtml(value: unknown): string {
	return String(value ?? "")
		.replace(/&/g, "&amp;")
		.replace(/</g, "&lt;")
		.replace(/>/g, "&gt;")
		.replace(/"/g, "&quot;")
		.replace(/'/g, "&#39;");
}

function nl2br(value: string): string {
	return escapeHtml(value).replace(/\n/g, "<br>");
}

function renderLightMarkdown(value: string): string {
	const lines = escapeHtml(value).split("\n");
	let inList = false;
	const out: string[] = [];

	for (const line of lines) {
		const heading = /^(#{1,4})\s+(.*)$/.exec(line);
		const bullet = /^\s*[-*]\s+(.*)$/.exec(line);
		if (heading) {
			if (inList) {
				out.push("</ul>");
				inList = false;
			}
			const level = Math.min(heading[1].length + 2, 6);
			out.push(`<h${level}>${heading[2]}</h${level}>`);
		} else if (bullet) {
			if (!inList) {
				out.push("<ul>");
				inList = true;
			}
			out.push(`<li>${bullet[1]}</li>`);
		} else if (line.trim()) {
			if (inList) {
				out.push("</ul>");
				inList = false;
			}
			out.push(`<p>${line}</p>`);
		} else if (inList) {
			out.push("</ul>");
			inList = false;
		}
	}
	if (inList) out.push("</ul>");
	return out.join("\n");
}

function mimeForPath(filePath: string): string {
	switch (path.extname(filePath).toLowerCase()) {
		case ".jpg":
		case ".jpeg":
			return "image/jpeg";
		case ".png":
			return "image/png";
		case ".gif":
			return "image/gif";
		case ".webp":
			return "image/webp";
		case ".svg":
			return "image/svg+xml";
		default:
			return "application/octet-stream";
	}
}

function isRemoteOrDataSrc(src: string): boolean {
	return /^(https?:|data:|blob:)/i.test(src);
}

function prepareAssetSrc(src: string | undefined, cwd: string, assets: Asset[]): string | undefined {
	if (!src) return undefined;
	if (isRemoteOrDataSrc(src)) return src;

	const absolutePath = path.isAbsolute(src) ? src : path.resolve(cwd, src);
	if (!existsSync(absolutePath)) return src;

	const id = `asset-${assets.length + 1}`;
	assets.push({ id, absolutePath, mimeType: mimeForPath(absolutePath) });
	return `/asset/${encodeURIComponent(id)}`;
}

function prepareForm(input: AskHumanHtmlInput): PreparedForm {
	const sectionIds = new Set<string>();
	const questionIds = new Set<string>();

	return {
		...input,
		sections: input.sections.map((section, sectionIndex) => {
			const sectionId = uniqueId(section.id || section.title || `section-${sectionIndex + 1}`, sectionIds);
			return {
				...section,
				id: sectionId,
				questions: section.questions.map((question, questionIndex) => {
					const id = uniqueId(question.id || question.label || `question-${sectionIndex + 1}-${questionIndex + 1}`, questionIds);
					let questionType = question.type;
					if (!questionType) questionType = question.options && question.options.length > 0 ? "radio" : "textarea";
					const options =
						questionType === "confirm" && (!question.options || question.options.length === 0)
							? [
									{ value: "yes", label: "Yes" },
									{ value: "no", label: "No" },
									{ value: "not_sure", label: "Not sure / discuss more" },
								]
							: question.options || [];
					return {
						...question,
						id,
						formName: `q_${id}`,
						type: questionType,
						options,
					};
				}),
			};
		}),
	};
}

function renderContextBlock(block: ContextBlock, cwd: string, assets: Asset[]): string {
	const kind = block.type || "markdown";
	const title = block.title ? `<h4>${escapeHtml(block.title)}</h4>` : "";

	if (kind === "image" || (kind === "diagram" && block.src)) {
		const src = prepareAssetSrc(block.src, cwd, assets);
		const image = src
			? `<img src="${escapeHtml(src)}" alt="${escapeHtml(block.alt || block.caption || block.title || kind)}">`
			: "";
		const caption = block.caption ? `<figcaption>${escapeHtml(block.caption)}</figcaption>` : "";
		return `<figure class="context-block media">${title}${image}${caption}</figure>`;
	}

	if (kind === "code" || kind === "diagram") {
		const label = block.language ? `<div class="code-label">${escapeHtml(block.language)}</div>` : "";
		const className = kind === "diagram" ? "diagram-source" : "code-source";
		return `<div class="context-block">${title}${label}<pre class="${className}"><code>${escapeHtml(block.content || "")}</code></pre></div>`;
	}

	if (kind === "text") {
		return `<div class="context-block">${title}<p>${nl2br(block.content || "")}</p></div>`;
	}

	return `<div class="context-block markdown">${title}${renderLightMarkdown(block.content || "")}</div>`;
}

function renderQuestion(question: PreparedQuestion): string {
	const name = escapeHtml(question.formName);
	const otherName = `${name}__other`;
	const discussName = `${name}__discuss_more`;
	const required = question.required ? " required" : "";
	const help = question.help ? `<p class="help">${nl2br(question.help)}</p>` : "";
	const options = question.options.map((option, index) => {
		const value = escapeHtml(option.value || option.label);
		const id = `${name}_${index}`;
		const description = option.description ? `<span class="option-description">${escapeHtml(option.description)}</span>` : "";
		return `<label class="option" for="${id}">
			<input id="${id}" type="${question.type === "checkbox" ? "checkbox" : "radio"}" name="${name}" value="${value}"${required}>
			<span><strong>${escapeHtml(option.label)}</strong>${description}</span>
		</label>`;
	});

	let inputHtml = "";
	if (question.type === "text") {
		inputHtml = `<input class="text-input" type="text" name="${name}"${required}>`;
	} else if (question.type === "textarea") {
		inputHtml = `<textarea class="textarea-input" name="${name}" rows="5"${required}></textarea>`;
	} else {
		inputHtml = `<div class="options">${options.join("\n")}</div>`;
	}

	return `<article class="question" data-question-id="${escapeHtml(question.id)}">
		<h3>${escapeHtml(question.label)}${question.required ? " <span class=\"required\">*</span>" : ""}</h3>
		${help}
		${inputHtml}
		<label class="discuss-more">
			<input type="checkbox" name="${discussName}" value="yes">
			<span>Discuss this more before making a final decision</span>
		</label>
		<label class="other-label" for="${otherName}">Other option / extra context</label>
		<textarea class="other-input" id="${otherName}" name="${otherName}" rows="3" placeholder="Write another option, caveat, constraint, or anything the choices miss."></textarea>
	</article>`;
}

function renderHtml(form: PreparedForm, cwd: string, assets: Asset[], submitPath: string): string {
	const questionDefs = form.sections.flatMap((section) =>
		section.questions.map((question) => ({
			sectionId: section.id,
			sectionTitle: section.title,
			id: question.id,
			label: question.label,
			type: question.type,
			formName: question.formName,
		})),
	);
	const sectionsHtml = form.sections
		.map((section) => {
			const contextBlocks = section.context || [];
			const contextHtml = contextBlocks.length
				? `<details class="context-toggle"${section.initiallyOpen === false ? "" : " open"}>
					<summary>Context for this section</summary>
					${contextBlocks.map((block) => renderContextBlock(block, cwd, assets)).join("\n")}
				</details>`
				: "";
			const summary = section.summary ? `<p class="section-summary">${nl2br(section.summary)}</p>` : "";
			return `<section class="section" id="${escapeHtml(section.id)}">
				<header><h2>${escapeHtml(section.title)}</h2>${summary}</header>
				${contextHtml}
				<div class="questions">${section.questions.map(renderQuestion).join("\n")}</div>
			</section>`;
		})
		.join("\n");

	return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${escapeHtml(form.title)}</title>
<style>
:root { color-scheme: dark; --bg:#161b1e; --card:#273136; --panel:#3a4449; --muted:#8b9798; --text:#f2fffc; --soft:#b8c4c3; --yellow:#ffed72; --green:#a2e57b; --red:#ff6d7e; --orange:#ffb270; --blue:#7cd5f1; --purple:#baa0f8; }
* { box-sizing: border-box; }
body { margin: 0; font: 16px/1.5 ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; background: radial-gradient(circle at top left, #273136 0, var(--bg) 42rem); color: var(--text); }
main { width: min(1050px, calc(100vw - 32px)); margin: 0 auto; padding: 40px 0 56px; }
.hero { border: 1px solid #545f62; background: linear-gradient(135deg, rgba(58,68,73,.9), rgba(39,49,54,.92)); border-radius: 24px; padding: 28px; box-shadow: 0 28px 90px rgba(0,0,0,.32); }
h1 { margin: 0 0 8px; font-size: clamp(2rem, 5vw, 4rem); line-height: 1; color: var(--yellow); letter-spacing: -.04em; }
.intro { max-width: 78ch; color: var(--soft); margin: 12px 0 0; }
.meta { margin-top: 18px; color: var(--muted); font-size: .92rem; }
.section { margin-top: 24px; padding: 22px; border: 1px solid #545f62; border-radius: 22px; background: rgba(39,49,54,.9); }
.section h2 { margin: 0; color: var(--green); font-size: 1.55rem; }
.section-summary { color: var(--soft); margin: 8px 0 0; }
.context-toggle { margin: 18px 0 20px; border: 1px solid #545f62; border-radius: 16px; background: rgba(58,68,73,.65); overflow: hidden; }
.context-toggle > summary { cursor: pointer; padding: 14px 16px; color: var(--yellow); font-weight: 700; }
.context-block { padding: 0 16px 16px; color: var(--soft); }
.context-block h4 { color: var(--blue); margin: 16px 0 8px; }
.context-block p { margin: 8px 0; }
.context-block img { display: block; max-width: 100%; border-radius: 14px; border: 1px solid #545f62; background: #1d2528; }
figcaption { margin-top: 8px; color: var(--muted); font-size: .92rem; }
pre { overflow: auto; padding: 14px; border-radius: 14px; background: #1d2528; border: 1px solid #545f62; color: var(--text); }
.code-label { color: var(--purple); font-size: .85rem; margin: 6px 0; text-transform: uppercase; letter-spacing: .08em; }
.question { margin-top: 18px; padding: 18px; border-radius: 18px; background: rgba(22,27,30,.72); border: 1px solid rgba(84,95,98,.85); }
.question h3 { margin: 0 0 8px; color: var(--text); }
.required { color: var(--orange); }
.help { margin: 0 0 12px; color: var(--muted); }
.options { display: grid; gap: 10px; margin: 12px 0; }
.option, .discuss-more { display: flex; gap: 10px; align-items: flex-start; padding: 12px; border: 1px solid #545f62; border-radius: 14px; background: rgba(58,68,73,.55); cursor: pointer; }
.option:hover, .discuss-more:hover { border-color: var(--yellow); }
.option input, .discuss-more input { margin-top: 4px; accent-color: var(--yellow); }
.option-description { display: block; color: var(--muted); font-size: .94rem; margin-top: 2px; }
.text-input, .textarea-input, .other-input, .global-notes { width: 100%; border: 1px solid #545f62; border-radius: 14px; background: #1d2528; color: var(--text); padding: 12px; font: inherit; outline: none; }
.text-input:focus, .textarea-input:focus, .other-input:focus, .global-notes:focus { border-color: var(--yellow); box-shadow: 0 0 0 3px rgba(255,237,114,.12); }
.discuss-more { margin-top: 12px; color: var(--soft); }
.other-label { display: block; margin: 14px 0 6px; color: var(--orange); font-weight: 700; }
.submit-panel { position: sticky; bottom: 0; margin-top: 28px; padding: 18px; border: 1px solid #545f62; border-radius: 22px; background: rgba(29,37,40,.96); backdrop-filter: blur(14px); box-shadow: 0 -18px 60px rgba(0,0,0,.28); }
.submit-panel label { display:block; margin-bottom: 8px; color: var(--blue); font-weight: 700; }
button { margin-top: 14px; width: 100%; border: 0; border-radius: 16px; padding: 15px 18px; background: var(--yellow); color: #273136; font-weight: 900; font-size: 1.05rem; cursor: pointer; }
button:hover { filter: brightness(1.06); }
.status { margin-top: 12px; color: var(--muted); }
.status.error { color: var(--red); }
</style>
</head>
<body>
<main>
  <div class="hero">
    <h1>${escapeHtml(form.title)}</h1>
    ${form.intro ? `<p class="intro">${nl2br(form.intro)}</p>` : ""}
    <div class="meta">Generated by pi for human clarification. Current working directory: <code>${escapeHtml(cwd)}</code></div>
  </div>
  <form id="human-input-form">
    ${sectionsHtml}
    <div class="submit-panel">
      <label for="global_notes">Anything else pi should know?</label>
      <textarea id="global_notes" class="global-notes" name="global_notes" rows="4" placeholder="Optional global notes, corrections, constraints, or preferences."></textarea>
      <button type="submit">${escapeHtml(form.submitLabel || "Submit responses")}</button>
      <div id="status" class="status"></div>
    </div>
  </form>
</main>
<script>
const QUESTION_DEFS = ${JSON.stringify(questionDefs)};
const SUBMIT_PATH = ${JSON.stringify(submitPath)};
const form = document.getElementById('human-input-form');
const statusEl = document.getElementById('status');
function valueFor(formData, question) {
  if (question.type === 'checkbox') return formData.getAll(question.formName);
  return formData.get(question.formName) || '';
}
form.addEventListener('submit', async (event) => {
  event.preventDefault();
  statusEl.className = 'status';
  statusEl.textContent = 'Submitting…';
  const formData = new FormData(form);
  const responses = QUESTION_DEFS.map((question) => ({
    sectionId: question.sectionId,
    sectionTitle: question.sectionTitle,
    questionId: question.id,
    questionLabel: question.label,
    type: question.type,
    value: valueFor(formData, question),
    other: formData.get(question.formName + '__other') || '',
    discussMore: formData.get(question.formName + '__discuss_more') === 'yes'
  }));
  const payload = {
    title: ${JSON.stringify(form.title)},
    submittedAt: new Date().toISOString(),
    globalNotes: formData.get('global_notes') || '',
    responses
  };
  try {
    const response = await fetch(SUBMIT_PATH, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify(payload)
    });
    if (!response.ok) throw new Error(await response.text());
    document.body.innerHTML = '<main><div class="hero"><h1>Submitted</h1><p class="intro">Thanks. pi has received your responses, and you can close this tab.</p></div></main>';
  } catch (error) {
    statusEl.className = 'status error';
    statusEl.textContent = 'Submit failed: ' + (error && error.message ? error.message : String(error));
  }
});
</script>
</body>
</html>`;
}

function openBrowser(url: string): boolean {
	const platform = process.platform;
	const command = platform === "darwin" ? "open" : platform === "win32" ? "cmd" : "xdg-open";
	const args = platform === "win32" ? ["/c", "start", "", url] : [url];

	try {
		const child = spawn(command, args, { detached: true, stdio: "ignore" });
		child.unref();
		return true;
	} catch {
		return false;
	}
}

function readRequestBody(req: IncomingMessage, limitBytes: number, signal?: AbortSignal): Promise<string> {
	return new Promise((resolve, reject) => {
		let size = 0;
		const chunks: Buffer[] = [];
		const abort = () => reject(new Error("Request aborted"));
		signal?.addEventListener("abort", abort, { once: true });

		req.on("data", (chunk: Buffer) => {
			size += chunk.length;
			if (size > limitBytes) {
				reject(new Error("Submission too large"));
				req.destroy();
				return;
			}
			chunks.push(chunk);
		});
		req.on("end", () => {
			signal?.removeEventListener("abort", abort);
			resolve(Buffer.concat(chunks).toString("utf8"));
		});
		req.on("error", (error) => {
			signal?.removeEventListener("abort", abort);
			reject(error);
		});
	});
}

function send(res: ServerResponse, status: number, body: string, contentType = "text/plain; charset=utf-8") {
	res.writeHead(status, { "content-type": contentType, "cache-control": "no-store" });
	res.end(body);
}

async function askViaBrowser(
	input: AskHumanHtmlInput,
	cwd: string,
	signal?: AbortSignal,
	onReady?: (info: { url: string; pagePath: string; opened: boolean }) => void,
): Promise<HumanHtmlResult> {
	const prepared = prepareForm(input);
	const token = randomUUID();
	const assets: Asset[] = [];
	const outputDir = path.join(os.homedir(), ".pi", "agent", "human-input-pages");
	await fs.mkdir(outputDir, { recursive: true });

	const baseName = `${Date.now()}-${slug(prepared.title)}`;
	const pagePath = path.join(outputDir, `${baseName}.html`);
	const responsePath = path.join(outputDir, `${baseName}.response.json`);
	let html = "";
	let resolveSubmission: (result: HumanHtmlResult) => void;
	let rejectSubmission: (error: Error) => void;
	const submitted = new Promise<HumanHtmlResult>((resolve, reject) => {
		resolveSubmission = resolve;
		rejectSubmission = reject;
	});

	const server = createServer(async (req, res) => {
		try {
			const requestUrl = new URL(req.url || "/", "http://127.0.0.1");
			if (requestUrl.pathname === "/") {
				if (requestUrl.searchParams.get("token") !== token) return send(res, 403, "Invalid token");
				return send(res, 200, html, "text/html; charset=utf-8");
			}

			if (requestUrl.pathname.startsWith("/asset/") && req.method === "GET") {
				const id = decodeURIComponent(requestUrl.pathname.slice("/asset/".length));
				const asset = assets.find((item) => item.id === id);
				if (!asset) return send(res, 404, "Asset not found");
				const data = await fs.readFile(asset.absolutePath);
				res.writeHead(200, { "content-type": asset.mimeType, "cache-control": "no-store" });
				res.end(data);
				return;
			}

			if (requestUrl.pathname === "/submit" && req.method === "POST") {
				if (requestUrl.searchParams.get("token") !== token) return send(res, 403, "Invalid token");
				const body = await readRequestBody(req, 2 * 1024 * 1024, signal);
				const responses = JSON.parse(body) as unknown;
				const result: HumanHtmlResult = {
					title: prepared.title,
					url,
					pagePath,
					responsePath,
					submittedAt: new Date().toISOString(),
					responses,
				};
				await fs.writeFile(responsePath, JSON.stringify(result, null, 2));
				send(res, 200, "OK");
				resolveSubmission(result);
				return;
			}

			send(res, 404, "Not found");
		} catch (error) {
			send(res, 500, error instanceof Error ? error.message : String(error));
		}
	});

	await new Promise<void>((resolve, reject) => {
		server.once("error", reject);
		server.listen(0, "127.0.0.1", () => resolve());
	});

	const address = server.address();
	if (!address || typeof address === "string") {
		server.close();
		throw new Error("Could not determine browser form server address");
	}

	const url = `http://127.0.0.1:${address.port}/?token=${encodeURIComponent(token)}`;
	const submitPath = `/submit?token=${encodeURIComponent(token)}`;
	html = renderHtml(prepared, cwd, assets, submitPath);
	await fs.writeFile(pagePath, html);

	const timeoutSeconds = Math.max(10, Math.min(input.timeoutSeconds ?? 3600, 24 * 60 * 60));
	const timeout = setTimeout(() => rejectSubmission(new Error(`Timed out waiting for human input after ${timeoutSeconds}s`)), timeoutSeconds * 1000);
	const abort = () => rejectSubmission(new Error("Human input request was aborted"));
	signal?.addEventListener("abort", abort, { once: true });

	try {
		const opened = input.autoOpen !== false ? openBrowser(url) : false;
		onReady?.({ url, pagePath, opened });
		return await submitted;
	} finally {
		clearTimeout(timeout);
		signal?.removeEventListener("abort", abort);
		server.close();
	}
}

function summarizeResponses(result: HumanHtmlResult): string {
	const payload = result.responses as {
		globalNotes?: string;
		responses?: Array<{
			sectionTitle?: string;
			questionLabel?: string;
			value?: unknown;
			other?: string;
			discussMore?: boolean;
		}>;
	};
	const lines = [`Human submitted responses for: ${result.title}`];
	let currentSection = "";
	for (const response of payload.responses || []) {
		if (response.sectionTitle && response.sectionTitle !== currentSection) {
			currentSection = response.sectionTitle;
			lines.push("", `## ${currentSection}`);
		}
		const value = Array.isArray(response.value) ? response.value.join(", ") : String(response.value || "");
		const extras = [response.other ? `other: ${response.other}` : "", response.discussMore ? "discuss more requested" : ""]
			.filter(Boolean)
			.join("; ");
		lines.push(`- ${response.questionLabel}: ${value || "(no direct selection)"}${extras ? ` (${extras})` : ""}`);
	}
	if (payload.globalNotes) lines.push("", `Global notes: ${payload.globalNotes}`);
	lines.push("", `Saved response: ${result.responsePath}`);
	return lines.join("\n");
}

export default function humanInputPageExtension(pi: ExtensionAPI) {
	pi.registerTool({
		name: "ask_human_html",
		label: "Ask Human (HTML)",
		description:
			"Open a local interactive HTML page to ask the human for clarification, input, or confirmation. Use this when a decision needs human judgment before continuing.",
		promptSnippet:
			"Ask the human via a local browser HTML form with sections, expandable context, choices, discuss-more toggles, and other-option text boxes.",
		promptGuidelines: [
			"Use ask_human_html whenever you need human input, clarification, preference selection, or confirmation before proceeding.",
			"When using ask_human_html, group the request into clear sections, include enough context for the human to decide without reading the full chat, and include images or diagrams when relevant.",
			"Every ask_human_html question automatically includes a discuss-more checkbox and an other-option text box; use radio buttons for one choice, checkboxes for multiple choices, confirm for yes/no, and textarea for open-ended answers.",
		],
		parameters: AskHumanHtmlParams,

		async execute(_toolCallId, params: AskHumanHtmlInput, signal, onUpdate, ctx) {
			if (!params.sections || params.sections.length === 0) {
				return {
					isError: true,
					content: [{ type: "text" as const, text: "ask_human_html requires at least one section." }],
					details: { error: "No sections provided" },
				};
			}

			onUpdate?.({ content: [{ type: "text", text: "Preparing human input page…" }] });

			try {
				const result = await askViaBrowser(params, ctx.cwd, signal, ({ url, pagePath, opened }) => {
					onUpdate?.({
						content: [
							{
								type: "text",
								text: `${opened ? "Opened" : "Created"} human input page: ${url}\nSaved HTML: ${pagePath}`,
							},
						],
					});
				});
				return {
					content: [{ type: "text" as const, text: summarizeResponses(result) }],
					details: result,
				};
			} catch (error) {
				return {
					isError: true,
					content: [
						{
							type: "text" as const,
							text: `Human input page failed: ${error instanceof Error ? error.message : String(error)}`,
						},
					],
					details: { error: error instanceof Error ? error.message : String(error) },
				};
			}
		},

		renderCall(args, theme) {
			const sectionCount = Array.isArray(args.sections) ? args.sections.length : 0;
			const title = typeof args.title === "string" ? args.title : "Human input";
			return new Text(
				theme.fg("toolTitle", theme.bold("ask_human_html ")) +
					theme.fg("muted", truncateToWidth(title, 72)) +
					theme.fg("dim", ` (${sectionCount} section${sectionCount === 1 ? "" : "s"})`),
				0,
				0,
			);
		},

		renderResult(result, _options, theme) {
			const details = result.details as Partial<HumanHtmlResult> | undefined;
			if (result.isError) {
				return new Text(theme.fg("error", "Human input failed"), 0, 0);
			}
			if (!details?.responsePath) {
				return new Text(theme.fg("success", "Human input received"), 0, 0);
			}
			return new Text(
				theme.fg("success", "✓ Human input received") + "\n" + theme.fg("dim", details.responsePath),
				0,
				0,
			);
		},
	});
}
