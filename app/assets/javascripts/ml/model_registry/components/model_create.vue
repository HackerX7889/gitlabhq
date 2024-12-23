<script>
import { GlAlert, GlButton, GlForm, GlFormGroup, GlFormInput } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { visitUrl } from '~/lib/utils/url_utility';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import { noSpacesRegex } from '~/lib/utils/regexp';
import createModelMutation from '../graphql/mutations/create_model.mutation.graphql';

export default {
  name: 'ModelCreate',
  components: {
    MarkdownEditor,
    GlAlert,
    GlButton,
    GlForm,
    GlFormGroup,
    GlFormInput,
  },
  inject: ['projectPath', 'maxAllowedFileSize', 'markdownPreviewPath'],
  props: {
    disableAttachments: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      name: null,
      description: '',
      errorMessage: null,
      modelData: null,
      markdownDocPath: helpPagePath('user/markdown'),
      markdownEditorRestrictedToolBarItems: ['full-screen'],
    };
  },
  computed: {
    autocompleteDataSources() {
      return gl.GfmAutoComplete?.dataSources;
    },
    modelNameIsValid() {
      return this.name && noSpacesRegex.test(this.name);
    },
    submitButtonDisabled() {
      return !this.modelNameIsValid;
    },
    modelNameDescription() {
      return !this.name || this.modelNameIsValid ? this.$options.i18n.nameDescription : '';
    },
  },
  methods: {
    async createModel() {
      const { data } = await this.$apollo.mutate({
        mutation: createModelMutation,
        variables: {
          projectPath: this.projectPath,
          name: this.name,
          description: this.description,
        },
      });
      return data;
    },
    async create() {
      this.errorMessage = '';
      try {
        // Attempt creating a model if needed
        if (!this.modelData) {
          this.modelData = await this.createModel();
        }
        const modelErrors = this.modelData?.mlModelCreate?.errors || [];
        if (modelErrors.length) {
          this.errorMessage = modelErrors.join(', ');
          this.modelData = null;
        } else {
          const { showPath } = this.modelData.mlModelCreate.model._links;
          visitUrl(showPath);
        }
      } catch (error) {
        Sentry.captureException(error);
        this.errorMessage = error;
      }
    },
    resetForm() {
      this.name = null;
      this.description = '';
      this.errorMessage = null;
      this.modelData = null;
    },
    hideAlert() {
      this.errorMessage = null;
    },
    setDescription(newText) {
      if (!this.isSubmitting) {
        this.description = newText;
      }
    },
  },
  descriptionFormFieldProps: {
    placeholder: s__('MlModelRegistry|Enter a model description'),
    id: 'model-description',
    name: 'model-description',
  },
  i18n: {
    actionPrimaryText: s__('MlModelRegistry|Create'),
    actionSecondaryText: __('Cancel'),
    nameDescriptionLabel: s__('MlModelRegistry|Must be unique. May not contain spaces.'),
    nameDescription: s__('MlModelRegistry|Example: my-model'),
    nameInvalid: s__('MlModelRegistry|May not contain spaces.'),
    namePlaceholder: s__('MlModelRegistry|Enter a model name'),
    nameDescriptionPlaceholder: s__('MlModelRegistry|Enter a model description'),
    title: s__('MlModelRegistry|Create model'),
    modelName: s__('MlModelRegistry|Model name'),
    modelDescription: __('Model description'),
    optionalText: s__('MlModelRegistry|(Optional)'),
  },
};
</script>

<template>
  <div>
    <h2>{{ $options.i18n.title }}</h2>
    <gl-form>
      <gl-form-group
        :label="$options.i18n.modelName"
        :label-description="$options.i18n.nameDescriptionLabel"
        label-for="nameId"
        data-testid="nameGroupId"
        :state="modelNameIsValid"
        :invalid-feedback="$options.i18n.nameInvalid"
        :description="modelNameDescription"
      >
        <gl-form-input
          id="nameId"
          v-model="name"
          data-testid="nameId"
          type="text"
          :placeholder="$options.i18n.namePlaceholder"
        />
      </gl-form-group>
      <gl-form-group
        :label="$options.i18n.modelDescription"
        data-testid="descriptionGroupId"
        label-for="descriptionId"
        optional
        :optional-text="$options.i18n.optionalText"
        class="common-note-form gfm-form js-main-target-form new-note gl-grow"
      >
        <markdown-editor
          ref="markdownEditor"
          data-testid="descriptionId"
          :value="description"
          enable-autocomplete
          :autocomplete-data-sources="autocompleteDataSources"
          :enable-content-editor="true"
          :form-field-props="$options.descriptionFormFieldProps"
          :render-markdown-path="markdownPreviewPath"
          :markdown-docs-path="markdownDocPath"
          :disable-attachments="disableAttachments"
          :placeholder="$options.i18n.nameDescriptionPlaceholder"
          :restricted-tool-bar-items="markdownEditorRestrictedToolBarItems"
          @input="setDescription"
        />
      </gl-form-group>
    </gl-form>

    <gl-alert v-if="errorMessage" data-testid="create-alert" variant="danger" @dismiss="hideAlert"
      >{{ errorMessage }}
    </gl-alert>

    <gl-button data-testid="secondary-button" variant="default" @click="resetForm"
      >{{ $options.i18n.actionSecondaryText }}
    </gl-button>

    <gl-button
      data-testid="primary-button"
      variant="confirm"
      :disabled="submitButtonDisabled"
      @click="create"
      >{{ $options.i18n.actionPrimaryText }}
    </gl-button>
  </div>
</template>
