import gpt4all
import sys

def summarize_text(input_text):
    gptj = gpt4all.GPT4All("ggml-gpt4all-j-v1.3-groovy")
    messages = [{"role": "user", "content": "Summarize the following text in less than 2000 characters:\n\n" + input_text + "\n\n---\n\nSummary:"}]

    return gptj.chat_completion(messages, verbose=False, streaming=False)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Please provide the input text as a command-line argument.")
    else:
        input_text = " ".join(sys.argv[1:])
        result = summarize_text(input_text)

        if result != None:
            print("#" + result["choices"][0]["message"]["content"])
